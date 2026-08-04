-- Query 8: Statistics of FIFA Players by Location
-- This query identifies locations that have trained or hosted at least
-- two members who have participated in FIFA games.
-- It also provides information about the location, general manager,
-- member distribution, and number of FIFA players.

SELECT 
    l.LocationID,
    l.Name AS location_name,
    l.Address,
    l.City,
    l.Province,
    l.PostalCode,
    l.Phone,
    l.WebAddress,
    l.Type,
    l.Capacity,

    -- Retrieve the full name of the location's general manager
    CONCAT(p.FirstName, ' ', p.LastName) AS general_manager_name,

    -- Count the number of minor members associated with this location
    COUNT(DISTINCT CASE 
        WHEN cm.MemberType = 'Minor' THEN cm.MemberID 
    END) AS minor_member_count,

    -- Count the number of major members associated with this location
    COUNT(DISTINCT CASE 
        WHEN cm.MemberType = 'Major' THEN cm.MemberID 
    END) AS major_member_count,

    -- Count the number of unique members who participated in FIFA games
    COUNT(DISTINCT gp.MemberID) AS fifa_player_count

FROM Locations l

-- Join with Personnel table to get the general manager information
LEFT JOIN Personnel p 
    ON l.ManagerID = p.PersonnelID

-- Retrieve the historical relationship between members and locations
LEFT JOIN Member_Location_History mlh 
    ON l.LocationID = mlh.LocationID

-- Retrieve member details, including member type
LEFT JOIN ClubMembers cm 
    ON mlh.MemberID = cm.MemberID

-- Retrieve FIFA game participation records
LEFT JOIN Game_Participation gp 
    ON cm.MemberID = gp.MemberID

-- Group results by each location and its related attributes
GROUP BY 
    l.LocationID,
    l.Name,
    l.Address,
    l.City,
    l.Province,
    l.PostalCode,
    l.Phone,
    l.WebAddress,
    l.Type,
    l.Capacity,
    general_manager_name

-- Only display locations with at least two FIFA players
HAVING COUNT(DISTINCT gp.MemberID) >= 2

-- Rank locations by the number of FIFA players in descending order
ORDER BY fifa_player_count DESC;
