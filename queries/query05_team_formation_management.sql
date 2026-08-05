-- Query 05: Team Formation Management
-- teamID 1 and headCoachID 5 must exist in the seed data.

INSERT INTO Sessions (startDateTime, address, sessionType)
VALUES ('2026-09-12 10:30:00',
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
DELETE FROM TeamFormations WHERE formationID = @newFormationID;
