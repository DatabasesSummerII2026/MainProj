-- Requirement 10: all team formations at one location over a period.
-- The GUI binds the three variables below. Set them by hand to run this file on its own.

SET @locationID = 1;
SET @fromDate   = '2026-01-01 00:00:00';
SET @toDate     = '2026-06-01 00:00:00';   -- half-open: [from, to)

SELECT
    p.firstName                 AS coachFirstName,
    p.lastName                  AS coachLastName,
    s.startDateTime             AS sessionStart,
    s.address                   AS sessionAddress,
    s.sessionType,
    t.teamName,
    tf.score,
    (SELECT COUNT(*) FROM FormationPlayers fp2
      WHERE fp2.formationID = tf.formationID)   AS totalPlayers,
    cm.firstName                AS playerFirstName,
    cm.lastName                 AS playerLastName,
    fp.playerRole
FROM TeamFormations tf
JOIN Sessions        s  ON s.sessionID   = tf.sessionID
JOIN Teams           t  ON t.teamID      = tf.teamID
JOIN Personnel       p  ON p.personnelID = tf.headCoachID
LEFT JOIN FormationPlayers fp ON fp.formationID = tf.formationID
LEFT JOIN ClubMembers      cm ON cm.memberID    = fp.memberID
WHERE t.locationID = @locationID
  AND s.startDateTime >= @fromDate
  AND s.startDateTime <  @toDate
ORDER BY s.startDateTime ASC, t.teamName, fp.playerRole;
