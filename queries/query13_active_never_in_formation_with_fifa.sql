-- Requirement 13: active members never assigned to any formation who played at least one FIFA game. Sorted by location, then FIFA games ascending.
-- This is the requirement that forces FIFA_Games and Game_Participation to be their own relations. Model FIFA participation as formation assignment and this report can never return a row.

SELECT
    vms.memberID            AS clubMembershipNumber,
    vms.firstName,
    vms.lastName,
    vms.age,
    vms.phone,
    vms.email,
    COUNT(DISTINCT gp.gameID) AS fifaGames,
    vms.currentLocationName
FROM v_MemberStatus vms
JOIN Game_Participation gp ON gp.memberID = vms.memberID
WHERE vms.status = 'Active'
  AND NOT EXISTS (SELECT 1 FROM FormationPlayers fp
                   WHERE fp.memberID = vms.memberID)
GROUP BY vms.memberID, vms.firstName, vms.lastName, vms.age, vms.phone,
         vms.email, vms.currentLocationName
ORDER BY vms.currentLocationName ASC, fifaGames ASC;
