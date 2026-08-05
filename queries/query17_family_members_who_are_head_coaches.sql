-- Requirement 17: for one location, family members who have currently active club members associated with them and are also head coaches there.
-- A person can exist as both Personnel and a FamilyMember. SSN is unique and never null for personnel, so it is the join key between the two roles. Put this in the report assumptions.

SET @locationID = 1;

SELECT DISTINCT
    fm.firstName,
    fm.lastName,
    fm.phone
FROM FamilyMembers fm
JOIN Personnel p ON p.SSN = fm.SSN
WHERE EXISTS (                                   -- head coach at this location
        SELECT 1
          FROM TeamFormations tf
          JOIN Teams t ON t.teamID = tf.teamID
         WHERE tf.headCoachID = p.personnelID
           AND t.locationID   = @locationID)
  AND EXISTS (                                   -- has a currently active member
        SELECT 1
          FROM FamilyRelationship fr
          JOIN v_MemberStatus vms ON vms.memberID = fr.memberID
         WHERE fr.familyID = fm.familyID
           AND fr.endDate IS NULL
           AND vms.status = 'Active')
ORDER BY fm.lastName, fm.firstName;
