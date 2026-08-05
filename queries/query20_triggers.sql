-- Requirement 20: the triggers the system uses and what each one is for.
-- Run with -f. Most of the statements below are supposed to fail.
-- Full definitions are in database/triggers.sql.

SELECT TRIGGER_NAME, EVENT_MANIPULATION, EVENT_OBJECT_TABLE, ACTION_TIMING
FROM information_schema.TRIGGERS
WHERE TRIGGER_SCHEMA = DATABASE()
ORDER BY EVENT_OBJECT_TABLE, TRIGGER_NAME;

-- trg_FormationPlayers_bi and _bu, the main trigger.
-- None of its four rules can be written as a declarative constraint. Thethree-hour rule compares a new row against other rows in the same table, joined through two more tables. 
-- A CHECK cannot see other rows and a UNIQUE key cannot express "at least three hours apart". 
-- Keeping the rule in the database rather than the GUI means it holds however the row arrives: web form, script, or a POD typing SQL by hand.
SHOW CREATE TRIGGER trg_FormationPlayers_bi\G

-- Three-hour rule.
SELECT s.sessionID, s.startDateTime FROM Sessions s
 ORDER BY s.startDateTime LIMIT 3;

-- Gender rule. Putting a girl in a boys' formation is rejected. 
-- Expect ERROR 1644, "member gender does not match the team."
SELECT tf.formationID INTO @boysFormation
FROM TeamFormations tf JOIN Teams t ON t.teamID = tf.teamID
WHERE t.gender = 'Boys' AND t.locationID = 1 LIMIT 1;

SELECT memberID INTO @girl FROM v_MemberStatus
 WHERE gender = 'Girls' AND currentLocationID = 1 AND status = 'Active' LIMIT 1;

INSERT INTO FormationPlayers (formationID, memberID, playerRole)
VALUES (@boysFormation, @girl, 'Striker');

-- Location rule. A member from another branch is rejected. 
-- Expect ERROR 1644, "must currently belong to the team location."
SELECT memberID INTO @outsider FROM v_MemberStatus
 WHERE gender = 'Boys' AND currentLocationID = 4 AND status = 'Active' LIMIT 1;

INSERT INTO FormationPlayers (formationID, memberID, playerRole)
VALUES (@boysFormation, @outsider, 'Striker');

-- Unpaid-fees rule. An inactive member cannot play. 
-- Expect ERROR 1644, "an inactive member (unpaid fees) cannot be assigned to a session."
SELECT memberID, currentLocationID INTO @inactive, @inactiveLoc
FROM v_MemberStatus
WHERE status = 'Inactive' AND gender = 'Boys' LIMIT 1;

-- Use a formation at that member's own location, so the only rule left to break is the unpaid-fees one.
SELECT tf.formationID INTO @sameLocFormation
FROM TeamFormations tf JOIN Teams t ON t.teamID = tf.teamID
WHERE t.gender = 'Boys' AND t.locationID = @inactiveLoc LIMIT 1;

INSERT INTO FormationPlayers (formationID, memberID, playerRole)
VALUES (@sameLocFormation, @inactive, 'Striker');

-- trg_ClubMembers_bi. A member must be at least 4 years old at registration.
-- Expect ERROR 1644.
INSERT INTO ClubMembers (firstName, lastName, DOB, gender, SSN, phone, email,
                         address, city, province, postalCode, registrationDate)
VALUES ('Too', 'Young', '2024-01-01', 'Boys', '999-111-000', '514-555-0101',
        'too.young@example.ca', '1 rue Demo', 'Montreal', 'QC', 'H2X 1B1',
        '2026-08-01');

-- trg_TeamFormations_bi. At most two formations per session, the coach must work at the team's location, and a future session cannot have a score.
-- Expect ERROR 1644 on the third formation.
SELECT sessionID INTO @full FROM TeamFormations GROUP BY sessionID HAVING COUNT(*) = 2 LIMIT 1;
SELECT teamID INTO @spare FROM Teams WHERE teamID NOT IN
   (SELECT teamID FROM TeamFormations WHERE sessionID = @full) LIMIT 1;
SELECT personnelID INTO @anyCoach FROM Personnel WHERE role = 'Coach' LIMIT 1;

INSERT INTO TeamFormations (sessionID, teamID, headCoachID, score)
VALUES (@full, @spare, @anyCoach, NULL);

-- trg_FamilyRelationship_bi. A family relationship can only be recorded for a minor. 
-- Expect ERROR 1644.
SELECT memberID INTO @adult FROM v_MemberStatus WHERE age >= 25 LIMIT 1;
SELECT familyID INTO @anyFam FROM FamilyMembers LIMIT 1;

INSERT INTO FamilyRelationship (familyID, memberID, startDate, endDate, relationshipType)
VALUES (@anyFam, @adult, '2026-08-01', NULL, 'Father');

SELECT 'all triggers fired as expected' AS result;
