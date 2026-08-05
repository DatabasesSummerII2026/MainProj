-- Requirement 11: members who played at least five FIFA games, sorted by game count descending.
-- The seed contains members who qualify, so this runs as-is with no setup and no cleanup.

SELECT
    cm.memberID                     AS clubMembershipNumber,
    cm.firstName,
    cm.lastName,
    COUNT(DISTINCT gp.gameID)       AS totalFifaGames,
    MIN(YEAR(fg.gameDate))          AS firstGameYear,
    MAX(YEAR(fg.gameDate))          AS lastGameYear
FROM ClubMembers cm
JOIN Game_Participation gp ON gp.memberID = cm.memberID
JOIN FIFA_Games         fg ON fg.gameID   = gp.gameID
GROUP BY cm.memberID, cm.firstName, cm.lastName
HAVING COUNT(DISTINCT gp.gameID) >= 5
ORDER BY totalFifaGames DESC;
