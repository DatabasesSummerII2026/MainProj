-- Query 06: Formation Player Assignment

-- Automatically find a formation and an eligible active member who currently
-- belongs to the same location and gender as the formation's team.
SET @testFormationID = (
    SELECT tf.formationID
    FROM TeamFormations AS tf
    JOIN Teams AS t ON t.teamID = tf.teamID
    JOIN Sessions AS targetSession ON targetSession.sessionID = tf.sessionID
    WHERE EXISTS (
        SELECT 1
        FROM v_MemberStatus AS vms
        WHERE vms.currentLocationID = t.locationID
          AND vms.gender = t.gender
          AND vms.status = 'Active'
          AND NOT EXISTS (
              SELECT 1
              FROM FormationPlayers AS fp
              WHERE fp.formationID = tf.formationID
                AND fp.memberID = vms.memberID
          )
          AND NOT EXISTS (
              SELECT 1
              FROM FormationPlayers AS existingFP
              JOIN TeamFormations AS existingTF
                  ON existingTF.formationID = existingFP.formationID
              JOIN Sessions AS existingSession
                  ON existingSession.sessionID = existingTF.sessionID
              WHERE existingFP.memberID = vms.memberID
                AND DATE(existingSession.startDateTime) =
                    DATE(targetSession.startDateTime)
                AND ABS(TIMESTAMPDIFF(
                    MINUTE,
                    existingSession.startDateTime,
                    targetSession.startDateTime
                )) < 180
          )
    )
    ORDER BY tf.formationID
    LIMIT 1
);

SET @testMemberID = (
    SELECT vms.memberID
    FROM v_MemberStatus AS vms
    JOIN TeamFormations AS tf ON tf.formationID = @testFormationID
    JOIN Teams AS t ON t.teamID = tf.teamID
    JOIN Sessions AS targetSession ON targetSession.sessionID = tf.sessionID
    WHERE vms.currentLocationID = t.locationID
      AND vms.gender = t.gender
      AND vms.status = 'Active'
      AND NOT EXISTS (
          SELECT 1
          FROM FormationPlayers AS fp
          WHERE fp.formationID = @testFormationID
            AND fp.memberID = vms.memberID
      )
      AND NOT EXISTS (
          SELECT 1
          FROM FormationPlayers AS existingFP
          JOIN TeamFormations AS existingTF
              ON existingTF.formationID = existingFP.formationID
          JOIN Sessions AS existingSession
              ON existingSession.sessionID = existingTF.sessionID
          WHERE existingFP.memberID = vms.memberID
            AND DATE(existingSession.startDateTime) =
                DATE(targetSession.startDateTime)
            AND ABS(TIMESTAMPDIFF(
                MINUTE,
                existingSession.startDateTime,
                targetSession.startDateTime
            )) < 180
      )
    ORDER BY vms.memberID
    LIMIT 1
);

-- Check the automatically selected IDs before inserting.
SELECT @testFormationID AS formationID, @testMemberID AS memberID;

INSERT INTO FormationPlayers (formationID, memberID, playerRole)
VALUES (@testFormationID, @testMemberID, 'Goalkeeper');

UPDATE FormationPlayers
SET playerRole = 'Striker'
WHERE formationID = @testFormationID
  AND memberID = @testMemberID;

SELECT fp.formationID, fp.memberID, fp.playerRole,
       cm.firstName, cm.lastName, s.startDateTime, s.sessionType
FROM FormationPlayers AS fp
JOIN ClubMembers AS cm ON cm.memberID = fp.memberID
JOIN TeamFormations AS tf ON tf.formationID = fp.formationID
JOIN Sessions AS s ON s.sessionID = tf.sessionID
ORDER BY fp.formationID, fp.memberID
LIMIT 5;

-- CONFLICT TEST: create another session exactly two hours after the original.
INSERT INTO Sessions (startDateTime, address, sessionType)
SELECT DATE_ADD(s.startDateTime, INTERVAL 2 HOUR),
       CONCAT('Conflict test - ', s.address),
       'Training'
FROM TeamFormations AS tf
JOIN Sessions AS s ON s.sessionID = tf.sessionID
WHERE tf.formationID = @testFormationID;
SET @conflictSessionID = LAST_INSERT_ID();

INSERT INTO TeamFormations (sessionID, teamID, headCoachID, score)
SELECT @conflictSessionID, tf.teamID, tf.headCoachID, NULL
FROM TeamFormations AS tf
WHERE tf.formationID = @testFormationID;
SET @conflictFormationID = LAST_INSERT_ID();

-- Expected Error 1644: the same member has a formation within three hours.
INSERT INTO FormationPlayers (formationID, memberID, playerRole)
VALUES (@conflictFormationID, @testMemberID, 'Striker');

-- Cleanup, so the script can be run again. The rejected INSERT above is
-- already visible in the output; nothing was written by it.
DELETE FROM Sessions WHERE sessionID = @conflictSessionID;

DELETE FROM FormationPlayers
WHERE formationID = @testFormationID AND memberID = @testMemberID;
