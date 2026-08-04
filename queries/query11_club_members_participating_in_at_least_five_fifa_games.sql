-- ============================================================
-- Query 11 Club Members Participating in at Least Five FIFA Games
--
-- Purpose:
--   Demonstrate club members who participated in at least
--   five FIFA games.
--
-- Workflow:
--   1. Start transaction
--   2. Insert temporary FIFA games
--   3. Insert player participation records
--   4. Execute Query 11
--   5. Rollback all changes
--
-- All inserted data will be removed after ROLLBACK.
-- ============================================================


-- ============================================================
-- Step 1: Start transaction
-- ============================================================

START TRANSACTION;



-- ============================================================
-- Step 2: Insert temporary FIFA games
--
-- Alex Martin (MemberID = 1)
-- Emma Wilson (MemberID = 3)
--
-- Each player participates in at least 5 games.
-- ============================================================


INSERT INTO FIFA_Games
(
    GameID,
    GameDate,
    LocationID,
    OpponentTeam,
    Score
)
VALUES

-- Alex Martin games
(9001, '2022-03-10', 1, 'Demo FC A', '2-1'),
(9002, '2023-05-15', 1, 'Demo FC B', '3-2'),
(9003, '2024-06-20', 1, 'Demo FC C', '1-0'),
(9004, '2025-07-25', 1, 'Demo FC D', '4-1'),
(9005, '2026-08-01', 1, 'Demo FC E', '2-2'),


-- Emma Wilson games
(9010, '2022-04-01', 3, 'Demo FC F', '1-0'),
(9011, '2023-04-01', 3, 'Demo FC G', '2-0'),
(9012, '2024-04-01', 3, 'Demo FC H', '3-1'),
(9013, '2025-04-01', 3, 'Demo FC I', '2-2'),
(9014, '2026-04-01', 3, 'Demo FC J', '4-0'),
(9015, '2026-05-01', 3, 'Demo FC K', '1-0');



-- ============================================================
-- Step 3: Insert temporary game participation records
--
-- TeamID must already exist in Teams table.
--
-- Existing teams:
--   TeamID = 1 Montreal Lions
--   TeamID = 3 Longueuil Tigers
-- ============================================================


INSERT INTO Game_Participation
(
    MemberID,
    GameID,
    TeamID
)
VALUES

-- Alex Martin participation
(1,9001,1),
(1,9002,1),
(1,9003,1),
(1,9004,1),
(1,9005,1),


-- Emma Wilson participation
(3,9010,3),
(3,9011,3),
(3,9012,3),
(3,9013,3),
(3,9014,3),
(3,9015,3);



-- ============================================================
-- Step 4: Query 11
--
-- Get club members who participated in at least five FIFA games.
--
-- Information:
--   - Membership number
--   - First name
--   - Last name
--   - Total FIFA games
--   - Minimum game year
--   - Maximum game year
--
-- Sorted by participation count descending.
-- ============================================================


SELECT

    cm.MemberID AS club_membership_number,

    cm.FirstName,

    cm.LastName,

    COUNT(gp.GameID) AS total_fifa_games,

    MIN(YEAR(fg.GameDate)) AS first_game_year,

    MAX(YEAR(fg.GameDate)) AS last_game_year


FROM ClubMembers cm


JOIN Game_Participation gp
ON cm.MemberID = gp.MemberID


JOIN FIFA_Games fg
ON gp.GameID = fg.GameID


GROUP BY

    cm.MemberID,

    cm.FirstName,

    cm.LastName


HAVING COUNT(gp.GameID) >= 5


ORDER BY

    total_fifa_games DESC;



-- ============================================================
-- Step 5: Rollback temporary data
--
-- Execute after screenshot/demo.
-- Database will return to original state.
-- ============================================================


ROLLBACK;
