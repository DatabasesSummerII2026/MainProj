-- Triggers and stored procedures. Run after schema.sql, before seed.sql.

DROP TRIGGER IF EXISTS trg_ClubMembers_bi;
DROP TRIGGER IF EXISTS trg_ClubMembers_bu;
DROP TRIGGER IF EXISTS trg_Payments_bi;
DROP TRIGGER IF EXISTS trg_FamilyRelationship_bi;
DROP TRIGGER IF EXISTS trg_TeamFormations_bi;
DROP TRIGGER IF EXISTS trg_TeamFormations_bu;
DROP TRIGGER IF EXISTS trg_FormationPlayers_bi;
DROP TRIGGER IF EXISTS trg_FormationPlayers_bu;
DROP PROCEDURE IF EXISTS sp_GenerateWeeklyEmails;
DROP PROCEDURE IF EXISTS sp_CheckFormationPlayer;

DELIMITER $$

-- A new member must be at least 4 years old on the registration date.
CREATE TRIGGER trg_ClubMembers_bi
BEFORE INSERT ON ClubMembers
FOR EACH ROW
BEGIN
    IF NEW.registrationDate < DATE_ADD(NEW.DOB, INTERVAL 4 YEAR) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Rejected: a club member must be at least 4 years old at registration.';
    END IF;
END$$

CREATE TRIGGER trg_ClubMembers_bu
BEFORE UPDATE ON ClubMembers
FOR EACH ROW
BEGIN
    IF NEW.registrationDate < DATE_ADD(NEW.DOB, INTERVAL 4 YEAR) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Rejected: a club member must be at least 4 years old at registration.';
    END IF;
END$$


-- At most four installments per member per membership year, and the installment number must be in range. Redundant with the UNIQUE key on 8.x, and the only thing enforcing it on 5.7.
CREATE TRIGGER trg_Payments_bi
BEFORE INSERT ON Payments
FOR EACH ROW
BEGIN
    DECLARE v_count INT;

    IF NEW.amount <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Rejected: payment amount must be positive.';
    END IF;

    IF NEW.installmentNumber < 1 OR NEW.installmentNumber > 4 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Rejected: installment number must be between 1 and 4.';
    END IF;

    SELECT COUNT(*) INTO v_count
      FROM Payments
     WHERE memberID = NEW.memberID
       AND membershipYear = NEW.membershipYear;

    IF v_count >= 4 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Rejected: a membership year may be paid in at most 4 installments.';
    END IF;
END$$


-- A family relationship can only reference a member who is a minor when the relationship starts.
CREATE TRIGGER trg_FamilyRelationship_bi
BEFORE INSERT ON FamilyRelationship
FOR EACH ROW
BEGIN
    DECLARE v_dob DATE;

    SELECT DOB INTO v_dob FROM ClubMembers WHERE memberID = NEW.memberID;

    IF TIMESTAMPDIFF(YEAR, v_dob, NEW.startDate) >= 18 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Rejected: a family relationship may only be recorded for a minor club member.';
    END IF;
END$$


-- Formation rules: at most two formations per session, the head coach must currently work at the team's location, and a session in the future cannot already have a score.
CREATE TRIGGER trg_TeamFormations_bi
BEFORE INSERT ON TeamFormations
FOR EACH ROW
BEGIN
    DECLARE v_count     INT;
    DECLARE v_start     DATETIME;
    DECLARE v_teamLoc   INT;
    DECLARE v_coachOK   INT;

    SELECT COUNT(*) INTO v_count
      FROM TeamFormations WHERE sessionID = NEW.sessionID;

    IF v_count >= 2 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Rejected: a session already has its two team formations.';
    END IF;

    SELECT startDateTime INTO v_start FROM Sessions WHERE sessionID = NEW.sessionID;

    IF v_start > NOW() AND NEW.score IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Rejected: a session in the future cannot have a score.';
    END IF;

    SELECT locationID INTO v_teamLoc FROM Teams WHERE teamID = NEW.teamID;

    SELECT COUNT(*) INTO v_coachOK
      FROM Personnel_Assignment
     WHERE personnelID = NEW.headCoachID
       AND locationID  = v_teamLoc
       AND endDate IS NULL;

    IF v_coachOK = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Rejected: the head coach does not currently operate at the team location.';
    END IF;
END$$

CREATE TRIGGER trg_TeamFormations_bu
BEFORE UPDATE ON TeamFormations
FOR EACH ROW
BEGIN
    DECLARE v_start DATETIME;

    SELECT startDateTime INTO v_start FROM Sessions WHERE sessionID = NEW.sessionID;

    IF v_start > NOW() AND NEW.score IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Rejected: a session in the future cannot have a score.';
    END IF;
END$$


-- The main trigger. Four rules checked before a player joins a formation:
--   Three-hour rule. If the player is already in a formation the same day, the two sessions must start at least three hours apart. This also blocks putting one player on both sides of a session, since that gap is zero.
--   Gender. The player's gender must match the team's.
--   Location. Every player must currently belong to the team's location.
--   Fees. An inactive member cannot take part in any game or activity.
-- The logic sits in one procedure so INSERT and UPDATE cannot drift apart.
CREATE PROCEDURE sp_CheckFormationPlayer(IN p_formationID INT, IN p_memberID INT)
BEGIN
    DECLARE v_start      DATETIME;
    DECLARE v_teamID     INT;
    DECLARE v_teamGender VARCHAR(10);
    DECLARE v_teamLoc    INT;
    DECLARE v_memGender  VARCHAR(10);
    DECLARE v_memLoc     INT;
    DECLARE v_status     VARCHAR(10);
    DECLARE v_conflicts  INT;

    SELECT s.startDateTime, t.teamID, t.gender, t.locationID
      INTO v_start, v_teamID, v_teamGender, v_teamLoc
      FROM TeamFormations tf
      JOIN Sessions s ON s.sessionID = tf.sessionID
      JOIN Teams    t ON t.teamID    = tf.teamID
     WHERE tf.formationID = p_formationID;

    SELECT gender INTO v_memGender FROM ClubMembers WHERE memberID = p_memberID;

    SELECT locationID INTO v_memLoc
      FROM Member_Location_History
     WHERE memberID = p_memberID AND endDate IS NULL
     LIMIT 1;

    SELECT status INTO v_status FROM v_MemberStatus WHERE memberID = p_memberID;

    -- (b) gender
    IF v_memGender <> v_teamGender THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Rejected: players in a formation cannot be mixed - member gender does not match the team.';
    END IF;

    -- (c) location
    IF v_memLoc IS NULL OR v_memLoc <> v_teamLoc THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Rejected: all players in a formation must currently belong to the team location.';
    END IF;

    -- (d) fees
    IF v_status = 'Inactive' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Rejected: an inactive member (unpaid fees) cannot be assigned to a session.';
    END IF;

    -- (a) three-hour rule
    SELECT COUNT(*) INTO v_conflicts
      FROM FormationPlayers fp
      JOIN TeamFormations tf2 ON tf2.formationID = fp.formationID
      JOIN Sessions       s2  ON s2.sessionID    = tf2.sessionID
     WHERE fp.memberID    = p_memberID
       AND fp.formationID <> p_formationID
       AND DATE(s2.startDateTime) = DATE(v_start)
       AND ABS(TIMESTAMPDIFF(MINUTE, s2.startDateTime, v_start)) < 180;

    IF v_conflicts > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Rejected: the member is already assigned to another formation less than three hours away on the same day.';
    END IF;
END$$

CREATE TRIGGER trg_FormationPlayers_bi
BEFORE INSERT ON FormationPlayers
FOR EACH ROW
BEGIN
    CALL sp_CheckFormationPlayer(NEW.formationID, NEW.memberID);
END$$

CREATE TRIGGER trg_FormationPlayers_bu
BEFORE UPDATE ON FormationPlayers
FOR EACH ROW
BEGIN
    CALL sp_CheckFormationPlayer(NEW.formationID, NEW.memberID);
END$$


-- Weekly email generation, requirement 22.
-- Takes the Sunday the batch runs on and emails every player assigned to a session in the following seven days. One EmailLogs row per email.
-- The subject follows the example in the description:
--   "Montreal Group 6 Saturday 18-July-2026 2:00 PM training session"
-- Re-running for the same Sunday adds nothing, so the PODs can run it twice without filling the log with duplicates.
CREATE PROCEDURE sp_GenerateWeeklyEmails(IN p_sunday DATE)
BEGIN
    INSERT INTO EmailLogs
        (emailDateTime, senderLocationID, receiverMemberID, receiverEmail,
         subject, bodyPreview, body, sessionID)
    SELECT
        TIMESTAMP(p_sunday, '08:00:00'),
        t.locationID,
        cm.memberID,
        cm.email,
        CONCAT(t.teamName, ' ',
               DATE_FORMAT(s.startDateTime, '%W %e-%M-%Y %l:%i %p'), ' ',
               LOWER(s.sessionType), ' session'),
        LEFT(CONCAT('Dear ', cm.firstName, ' ', cm.lastName,
                    ', you are scheduled as ', fp.playerRole,
                    ' for the ', LOWER(s.sessionType), ' session on ',
                    DATE_FORMAT(s.startDateTime, '%e-%M-%Y at %l:%i %p'),
                    '. Head coach: ', p.firstName, ' ', p.lastName,
                    ' (', p.email, '). Address: ', s.address, '.'), 100),
        CONCAT('Dear ', cm.firstName, ' ', cm.lastName,
               ', you are scheduled as ', fp.playerRole,
               ' for the ', LOWER(s.sessionType), ' session on ',
               DATE_FORMAT(s.startDateTime, '%e-%M-%Y at %l:%i %p'),
               '. Head coach: ', p.firstName, ' ', p.lastName,
               ' (', p.email, '). Address: ', s.address, '.'),
        s.sessionID
    FROM Sessions s
    JOIN TeamFormations  tf ON tf.sessionID   = s.sessionID
    JOIN Teams           t  ON t.teamID       = tf.teamID
    JOIN Personnel       p  ON p.personnelID  = tf.headCoachID
    JOIN FormationPlayers fp ON fp.formationID = tf.formationID
    JOIN ClubMembers     cm ON cm.memberID    = fp.memberID
    WHERE s.startDateTime >= p_sunday
      AND s.startDateTime <  DATE_ADD(p_sunday, INTERVAL 7 DAY)
      AND NOT EXISTS (
            SELECT 1 FROM EmailLogs el
             WHERE el.sessionID        = s.sessionID
               AND el.receiverMemberID = cm.memberID
               AND DATE(el.emailDateTime) = p_sunday);
END$$

DELIMITER ;

-- Optionally let the server run this every Sunday at 08:00. Left commented because AITS may have the event scheduler off, in which case the demo calls sp_GenerateWeeklyEmails() directly.
-- SET GLOBAL event_scheduler = ON;
-- CREATE EVENT ev_WeeklyEmails
--   ON SCHEDULE EVERY 1 WEEK
--   STARTS '2026-08-09 08:00:00'
--   DO CALL sp_GenerateWeeklyEmails(CURDATE());
