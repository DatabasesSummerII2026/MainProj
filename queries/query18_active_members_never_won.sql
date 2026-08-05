-- Requirement 18: active members who played at least one game session and never won one. Sorted by location then membership number.
-- Won means the member's formation scored more than the other formation in the same session. That comparison needs Sessions to pair the two formations, and cannot be written against a flat formation table.

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
  AND EXISTS (                                   -- played at least one game
        SELECT 1
          FROM FormationPlayers fp
          JOIN TeamFormations tf ON tf.formationID = fp.formationID
          JOIN Sessions       s  ON s.sessionID    = tf.sessionID
         WHERE fp.memberID = vms.memberID
           AND s.sessionType = 'Game')
  AND NOT EXISTS (                               -- never won one
        SELECT 1
          FROM FormationPlayers fp
          JOIN TeamFormations tf  ON tf.formationID = fp.formationID
          JOIN Sessions       s   ON s.sessionID    = tf.sessionID
          JOIN TeamFormations opp ON opp.sessionID  = tf.sessionID
                                 AND opp.formationID <> tf.formationID
         WHERE fp.memberID = vms.memberID
           AND s.sessionType = 'Game'
           AND tf.score IS NOT NULL
           AND opp.score IS NOT NULL
           AND tf.score > opp.score)
ORDER BY vms.currentLocationName ASC, vms.memberID ASC;
