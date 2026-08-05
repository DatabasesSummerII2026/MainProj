-- Requirement 21: proof that the constraints in the description hold.
-- Run with -f. Each block names a rule, then either tries to break it or counts violations, which should always be zero.

SELECT '--- 1. A player cannot be in two formations less than 3 hours apart ---' AS rule;
-- Shown in full by 06_assign_player_to_formation.sql.
SELECT fp.memberID, s.startDateTime
FROM FormationPlayers fp
JOIN TeamFormations tf ON tf.formationID = fp.formationID
JOIN Sessions s ON s.sessionID = tf.sessionID
GROUP BY fp.memberID, s.startDateTime
HAVING COUNT(*) > 0
ORDER BY fp.memberID, s.startDateTime LIMIT 5;

-- This returns zero on a correct database.
SELECT 'violations of the 3-hour rule (must be 0)' AS check_name, COUNT(*) AS violations
FROM FormationPlayers a
JOIN TeamFormations tfa ON tfa.formationID = a.formationID
JOIN Sessions sa ON sa.sessionID = tfa.sessionID
JOIN FormationPlayers b ON b.memberID = a.memberID AND b.formationID <> a.formationID
JOIN TeamFormations tfb ON tfb.formationID = b.formationID
JOIN Sessions sb ON sb.sessionID = tfb.sessionID
WHERE DATE(sa.startDateTime) = DATE(sb.startDateTime)
  AND ABS(TIMESTAMPDIFF(MINUTE, sa.startDateTime, sb.startDateTime)) < 180;

SELECT '--- 2. No mixed formations (all players same gender as the team) ---' AS rule;
SELECT 'gender violations (must be 0)' AS check_name, COUNT(*) AS violations
FROM FormationPlayers fp
JOIN TeamFormations tf ON tf.formationID = fp.formationID
JOIN Teams t  ON t.teamID   = tf.teamID
JOIN ClubMembers cm ON cm.memberID = fp.memberID
WHERE cm.gender <> t.gender;

SELECT '--- 3. All players in a formation belong to the team location ---' AS rule;
SELECT 'location violations (must be 0)' AS check_name, COUNT(*) AS violations
FROM FormationPlayers fp
JOIN TeamFormations tf ON tf.formationID = fp.formationID
JOIN Teams t ON t.teamID = tf.teamID
LEFT JOIN v_MemberCurrentLocation vcl ON vcl.memberID = fp.memberID
WHERE vcl.locationID IS NULL OR vcl.locationID <> t.locationID;

SELECT '--- 4. Every session has at most two formations ---' AS rule;
SELECT 'sessions with more than 2 formations (must be 0)' AS check_name, COUNT(*) AS violations
FROM (SELECT sessionID FROM TeamFormations GROUP BY sessionID HAVING COUNT(*) > 2) x;

SELECT '--- 5. A future session has no score ---' AS rule;
SELECT 'future sessions with a score (must be 0)' AS check_name, COUNT(*) AS violations
FROM TeamFormations tf JOIN Sessions s ON s.sessionID = tf.sessionID
WHERE s.startDateTime > NOW() AND tf.score IS NOT NULL;

SELECT '--- 6. At most four installments per member per year ---' AS rule;
SELECT 'years paid in more than 4 installments (must be 0)' AS check_name, COUNT(*) AS violations
FROM (SELECT memberID, membershipYear FROM Payments
       GROUP BY memberID, membershipYear HAVING COUNT(*) > 4) x;

SELECT '--- 7. Every minor has a current family member ---' AS rule;
SELECT 'minors with no family member (must be 0)' AS check_name, COUNT(*) AS violations
FROM v_MemberStatus vms
WHERE vms.memberType = 'Minor'
  AND NOT EXISTS (SELECT 1 FROM FamilyRelationship fr
                   WHERE fr.memberID = vms.memberID AND fr.endDate IS NULL);

SELECT '--- 8. Every member has exactly one current location ---' AS rule;
SELECT 'members with <> 1 current location (must be 0)' AS check_name, COUNT(*) AS violations
FROM (SELECT cm.memberID, (SELECT COUNT(*) FROM Member_Location_History mlh
                            WHERE mlh.memberID = cm.memberID AND mlh.endDate IS NULL) AS n
        FROM ClubMembers cm) x
WHERE n <> 1;

SELECT '--- 9. Every member registered at 4 years old or later ---' AS rule;
SELECT 'members registered too young (must be 0)' AS check_name, COUNT(*) AS violations
FROM ClubMembers WHERE registrationDate < DATE_ADD(DOB, INTERVAL 4 YEAR);

SELECT '--- 10. No location is over capacity ---' AS rule;
SELECT l.name, l.capacity, COUNT(vcl.memberID) AS activeMembers
FROM Locations l LEFT JOIN v_MemberCurrentLocation vcl ON vcl.locationID = l.locationID
GROUP BY l.locationID, l.name, l.capacity
HAVING activeMembers > l.capacity;
