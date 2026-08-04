-- Requirement 16: active members assigned at least once to each of goalkeeper, right fullback, sweeper, defending and striker across game sessions. Sorted by location then membership number.
-- Role names: "Sweeper" is the enum value Sweeper, "Defending" is Defending midfielder. Put this mapping in the report assumptions.

SELECT
    vms.memberID        AS clubMembershipNumber,
    vms.firstName,
    vms.lastName,
    vms.age,
    vms.phone,
    vms.email,
    vms.currentLocationName
FROM v_MemberStatus vms
WHERE vms.status = 'Active'
  AND (SELECT COUNT(DISTINCT fp.playerRole)
         FROM FormationPlayers fp
         JOIN TeamFormations tf ON tf.formationID = fp.formationID
         JOIN Sessions       s  ON s.sessionID    = tf.sessionID
        WHERE fp.memberID = vms.memberID
          AND s.sessionType = 'Game'
          AND fp.playerRole IN ('Goalkeeper','Right fullback','Sweeper',
                                'Defending midfielder','Striker')) = 5
ORDER BY vms.currentLocationName ASC, vms.memberID ASC;
