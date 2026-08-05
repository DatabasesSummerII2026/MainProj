-- Requirement 12: formation report per location over a period, limited to locations with at least four game sessions, sorted by game sessions descending.
-- The range is half-open. BETWEEN with a bare end date against a DATETIME column drops everything after midnight on that date.
-- Location comes from the team taking part, so a cross-location game counts once for each of the two locations.

SET @fromDate = '2026-01-01 00:00:00';
SET @toDate   = '2027-01-01 00:00:00';     -- half-open: [from, to)

SELECT
    l.name                                                              AS locationName,
    COUNT(DISTINCT CASE WHEN s.sessionType = 'Training'
                        THEN tf.formationID END)                        AS trainingFormations,
    SUM(CASE WHEN s.sessionType = 'Training' THEN 1 ELSE 0 END)         AS trainingPlayers,
    COUNT(DISTINCT CASE WHEN s.sessionType = 'Game'
                        THEN tf.formationID END)                        AS gameFormations,
    SUM(CASE WHEN s.sessionType = 'Game' THEN 1 ELSE 0 END)             AS gamePlayers
FROM Locations l
JOIN Teams           t  ON t.locationID   = l.locationID
JOIN TeamFormations  tf ON tf.teamID      = t.teamID
JOIN Sessions        s  ON s.sessionID    = tf.sessionID
LEFT JOIN FormationPlayers fp ON fp.formationID = tf.formationID
WHERE s.startDateTime >= @fromDate
  AND s.startDateTime <  @toDate
GROUP BY l.locationID, l.name
HAVING gameFormations >= 4
ORDER BY gameFormations DESC;
