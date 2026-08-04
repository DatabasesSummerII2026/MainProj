-- Requirement 8: locations with at least two members who played a FIFA game, sorted by number of FIFA players descending.
-- Membership comes from v_MemberCurrentLocation, so a member who transferred branch is not counted at both. Phone numbers come from Location_Phones because a location can have more than one.

SELECT
    l.locationID,
    l.name                                              AS locationName,
    l.address, l.city, l.province, l.postalCode,
    (SELECT GROUP_CONCAT(lp.phone SEPARATOR '; ')
       FROM Location_Phones lp WHERE lp.locationID = l.locationID) AS phoneNumbers,
    l.webAddress,
    l.type,
    l.capacity,
    CONCAT(mgr.firstName, ' ', mgr.lastName)            AS generalManager,
    SUM(CASE WHEN vms.memberType = 'Minor' THEN 1 ELSE 0 END) AS minorMembers,
    SUM(CASE WHEN vms.memberType = 'Major' THEN 1 ELSE 0 END) AS majorMembers,
    SUM(CASE WHEN EXISTS (SELECT 1 FROM Game_Participation gp
                           WHERE gp.memberID = vms.memberID)
             THEN 1 ELSE 0 END)                         AS fifaPlayers
FROM Locations l
LEFT JOIN Personnel      mgr ON mgr.personnelID     = l.managerID
LEFT JOIN v_MemberStatus vms ON vms.currentLocationID = l.locationID
GROUP BY l.locationID, l.name, l.address, l.city, l.province, l.postalCode,
         l.webAddress, l.type, l.capacity, mgr.firstName, mgr.lastName
HAVING fifaPlayers >= 2
ORDER BY fifaPlayers DESC;
