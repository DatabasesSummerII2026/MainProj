-- ============================================================
-- Query 12: Team Formation Report by Location
--
-- Purpose:
-- Generate a report for team formations during a given period.
--
-- Output:
--   Location name
--   Total training sessions
--   Total players in training sessions
--   Total game sessions
--   Total players in game sessions
--
-- Requirement:
--   Only include locations with at least four game sessions.
--
-- Workflow:
--   1. Start transaction
--   2. Insert temporary data
--   3. Execute query
--   4. Rollback
--
-- ============================================================


START TRANSACTION;



-- ============================================================
-- Step 1:
-- Insert temporary team formations
--
-- Location:
-- Montreal Head Office (LocationID = 1)
--
-- Team:
-- Montreal Lions (TeamID = 1)
--
-- Coach:
-- Sarah Miller (CoachID = 11)
--
-- ============================================================


INSERT INTO Team_Formations
(
    TeamID,
    LocationID,
    CoachID,
    StartTime,
    SessionType,
    Score
)
VALUES

(
    1,
    1,
    11,
    '2026-06-01 10:00:00',
    'Game',
    2
),

(
    1,
    1,
    11,
    '2026-07-01 15:00:00',
    'Game',
    3
),

(
    1,
    1,
    11,
    '2026-08-01 14:00:00',
    'Game',
    1
),

(
    1,
    1,
    11,
    '2026-09-01 16:00:00',
    'Game',
    4
),

(
    1,
    1,
    11,
    '2026-06-15 09:00:00',
    'Training',
    NULL
);



-- ============================================================
-- Step 2:
-- Insert players into newly created formations
--
-- IMPORTANT:
-- Do NOT manually use FormationID.
-- We retrieve formations using StartTime.
-- ============================================================


INSERT INTO Formation_Players
(
    FormationID,
    MemberID,
    PlayerRole
)

SELECT
    FormationID,
    1,
    'Striker'
FROM Team_Formations
WHERE StartTime='2026-06-01 10:00:00';



INSERT INTO Formation_Players
(
    FormationID,
    MemberID,
    PlayerRole
)

SELECT
    FormationID,
    2,
    'Goalkeeper'
FROM Team_Formations
WHERE StartTime='2026-06-01 10:00:00';




INSERT INTO Formation_Players
(
    FormationID,
    MemberID,
    PlayerRole
)

SELECT
    FormationID,
    1,
    'Striker'
FROM Team_Formations
WHERE StartTime='2026-07-01 15:00:00';



INSERT INTO Formation_Players
(
    FormationID,
    MemberID,
    PlayerRole
)

SELECT
    FormationID,
    2,
    'Goalkeeper'
FROM Team_Formations
WHERE StartTime='2026-07-01 15:00:00';




INSERT INTO Formation_Players
(
    FormationID,
    MemberID,
    PlayerRole
)

SELECT
    FormationID,
    1,
    'Striker'
FROM Team_Formations
WHERE StartTime='2026-08-01 14:00:00';



INSERT INTO Formation_Players
(
    FormationID,
    MemberID,
    PlayerRole
)

SELECT
    FormationID,
    3,
    'Sweeper'
FROM Team_Formations
WHERE StartTime='2026-08-01 14:00:00';




INSERT INTO Formation_Players
(
    FormationID,
    MemberID,
    PlayerRole
)

SELECT
    FormationID,
    1,
    'Striker'
FROM Team_Formations
WHERE StartTime='2026-09-01 16:00:00';



INSERT INTO Formation_Players
(
    FormationID,
    MemberID,
    PlayerRole
)

SELECT
    FormationID,
    2,
    'Goalkeeper'
FROM Team_Formations
WHERE StartTime='2026-09-01 16:00:00';




INSERT INTO Formation_Players
(
    FormationID,
    MemberID,
    PlayerRole
)

SELECT
    FormationID,
    1,
    'Striker'
FROM Team_Formations
WHERE StartTime='2026-06-15 09:00:00';



INSERT INTO Formation_Players
(
    FormationID,
    MemberID,
    PlayerRole
)

SELECT
    FormationID,
    2,
    'Goalkeeper'
FROM Team_Formations
WHERE StartTime='2026-06-15 09:00:00';



-- ============================================================
-- Step 3:
-- Query 12
-- ============================================================


SELECT

    l.Name AS location_name,


    COUNT(
        DISTINCT CASE
            WHEN tf.SessionType='Training'
            THEN tf.FormationID
        END
    ) AS total_training_sessions,


    COUNT(
        CASE
            WHEN tf.SessionType='Training'
            THEN fp.MemberID
        END
    ) AS total_training_players,


    COUNT(
        DISTINCT CASE
            WHEN tf.SessionType='Game'
            THEN tf.FormationID
        END
    ) AS total_game_sessions,


    COUNT(
        CASE
            WHEN tf.SessionType='Game'
            THEN fp.MemberID
        END
    ) AS total_game_players


FROM Locations l


JOIN Team_Formations tf
ON l.LocationID=tf.LocationID


LEFT JOIN Formation_Players fp
ON tf.FormationID=fp.FormationID



WHERE tf.StartTime BETWEEN
'2026-01-01'
AND
'2026-12-31'



GROUP BY

    l.LocationID,
    l.Name



HAVING

    COUNT(
        DISTINCT CASE
            WHEN tf.SessionType='Game'
            THEN tf.FormationID
        END
    ) >= 4



ORDER BY

    total_game_sessions DESC;



-- ============================================================
-- Step 4:
-- Remove temporary data
-- ============================================================


ROLLBACK;
