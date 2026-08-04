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

-- Montreal Lions training
(
    1,
    1,
    11,
    '2026-01-10 10:00:00',
    'Training',
    NULL
),

-- Montreal Lions game
(
    1,
    1,
    11,
    '2026-02-15 14:00:00',
    'Game',
    3
),

-- Laval Eagles training
(
    2,
    2,
    12,
    '2026-03-01 09:00:00',
    'Training',
    NULL
),

-- Toronto Wolves game
(
    4,
    4,
    11,
    '2026-04-10 16:00:00',
    'Game',
    2
),

-- Quebec Stars game
(
    6,
    6,
    12,
    '2026-05-20 15:00:00',
    'Game',
    1
);
