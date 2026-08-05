-- Requirement 19: volunteer personnel who are family members of at least one minor club member and have at least one associated member who played a FIFA game. Sorted by location, role, first name, last name.

SELECT
    p.firstName,
    p.lastName,
    (SELECT COUNT(DISTINCT fr.memberID)
       FROM FamilyRelationship fr
       JOIN v_MemberStatus v2 ON v2.memberID = fr.memberID
      WHERE fr.familyID = fm.familyID
        AND fr.endDate IS NULL
        AND v2.memberType = 'Minor')                    AS minorMembers,
    (SELECT COUNT(DISTINCT fr.memberID)
       FROM FamilyRelationship fr
       JOIN Game_Participation gp ON gp.memberID = fr.memberID
      WHERE fr.familyID = fm.familyID
        AND fr.endDate IS NULL)                         AS fifaMembers,
    p.telephone,
    p.email,
    l.name                                              AS currentLocationName,
    p.role                                              AS currentRole
FROM Personnel p
JOIN FamilyMembers fm ON fm.SSN = p.SSN
JOIN Personnel_Assignment pa ON pa.personnelID = p.personnelID AND pa.endDate IS NULL
JOIN Locations l ON l.locationID = pa.locationID
WHERE p.mandate = 'Volunteer'
  AND (SELECT COUNT(DISTINCT fr.memberID)
         FROM FamilyRelationship fr
         JOIN v_MemberStatus v2 ON v2.memberID = fr.memberID
        WHERE fr.familyID = fm.familyID
          AND fr.endDate IS NULL
          AND v2.memberType = 'Minor') >= 1
  AND (SELECT COUNT(DISTINCT fr.memberID)
         FROM FamilyRelationship fr
         JOIN Game_Participation gp ON gp.memberID = fr.memberID
        WHERE fr.familyID = fm.familyID
          AND fr.endDate IS NULL) >= 1
ORDER BY l.name ASC, p.role ASC, p.firstName ASC, p.lastName ASC;
