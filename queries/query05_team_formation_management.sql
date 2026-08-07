-- Query 05: Team Formation Management
-- teamID 1 and headCoachID 5 must exist in the seed data.

-- Dated in the past. trg_TeamFormations_bu rejects a score on a session that
-- has not happened yet, so a future date makes the UPDATE below fail.
INSERT INTO Sessions (startDateTime, address, sessionType)
VALUES ('2026-07-12 10:30:00',
        '725 Saint-Charles Street, Longueuil', 'Game');
SET @newSessionID = LAST_INSERT_ID();

INSERT INTO TeamFormations (sessionID, teamID, headCoachID, score)
VALUES (@newSessionID, 1, 5, NULL);
SET @newFormationID = LAST_INSERT_ID();

UPDATE TeamFormations
SET score = 3
WHERE formationID = @newFormationID;

SELECT tf.formationID, tf.sessionID, tf.teamID, tf.headCoachID, tf.score,
       s.startDateTime, s.address, s.sessionType
FROM TeamFormations AS tf
JOIN Sessions AS s ON s.sessionID = tf.sessionID
ORDER BY tf.formationID
LIMIT 5;

--  delete
-- Deleting the session cascades to the formation, so no orphan session is
-- left behind on each run.
DELETE FROM Sessions WHERE sessionID = @newSessionID;
