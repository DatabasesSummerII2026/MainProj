-- ============================================================
-- Query 10: Team Formation Details by Location and Time Period
--
-- Purpose:
--   Retrieve all team formations for a given location
--   and time period.
--
-- Information includes:
--   - Head coach name
--   - Session start time
--   - Session address
--   - Session type (Training/Game)
--   - Team name
--   - Score
--   - Total number of players
--   - Player names and roles
--
-- Results are sorted by session start time.
-- ============================================================


SELECT

    -- Head coach information
    CONCAT(p.FirstName, ' ', p.LastName) 
        AS head_coach_name,


    -- Session information
    tf.StartTime 
        AS session_time,

    l.Address 
        AS session_address,

    tf.SessionType 
        AS session_type,


    -- Team information
    t.TeamName,

    tf.Score,


    -- Total players in this formation
    player_count.total_players,


    -- Player information
    cm.FirstName 
        AS player_first_name,

    cm.LastName 
        AS player_last_name,

    fp.PlayerRole



FROM Team_Formations tf


-- Get location information
JOIN Locations l
    ON tf.LocationID = l.LocationID


-- Get team information
JOIN Teams t
    ON tf.TeamID = t.TeamID


-- Get coach information
JOIN Personnel p
    ON tf.CoachID = p.PersonnelID


-- Get players in formation
JOIN Formation_Players fp
    ON tf.FormationID = fp.FormationID


-- Get player details
JOIN ClubMembers cm
    ON fp.MemberID = cm.MemberID



-- Count players in each formation
JOIN
(
    SELECT
        FormationID,
        COUNT(DISTINCT MemberID) AS total_players

    FROM Formation_Players

    GROUP BY FormationID

) player_count

ON tf.FormationID = player_count.FormationID



WHERE tf.LocationID = 1

AND tf.StartTime BETWEEN
    '2026-01-01 00:00:00'
    AND
    '2026-05-31 23:59:59'


ORDER BY
    tf.StartTime ASC;
