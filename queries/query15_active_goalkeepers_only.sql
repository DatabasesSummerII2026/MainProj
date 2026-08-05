-- Requirement 15: active members who have only ever played goalkeeper and have played at least once. Sorted by location then membership number.
-- EXISTS for at least one goalkeeper assignment, NOT EXISTS for any assignment that is not goalkeeper. Counting goalkeeper appearances instead would wrongly pass a member with five goalkeeper rows and one striker row.

SELECT
    vms.memberID        AS clubMembershipNumber,
    vms.firstName,
    vms.lastName,
    vms.age,
    vms.phone,
    vms.email,
    vms.currentLocationName,
    (SELECT COUNT(DISTINCT gp.gameID) FROM Game_Participation gp
      WHERE gp.memberID = vms.memberID)     AS fifaGames
FROM v_MemberStatus vms
WHERE vms.status = 'Active'
  AND EXISTS     (SELECT 1 FROM FormationPlayers fp
                   WHERE fp.memberID = vms.memberID
                     AND fp.playerRole = 'Goalkeeper')
  AND NOT EXISTS (SELECT 1 FROM FormationPlayers fp
                   WHERE fp.memberID = vms.memberID
                     AND fp.playerRole <> 'Goalkeeper')
ORDER BY vms.currentLocationName ASC, vms.memberID ASC;
