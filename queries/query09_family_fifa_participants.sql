-- Requirement 9: primary family members with at least two associated members who played a FIFA game, sorted by family first name then last name.
-- Two filters matter: familyType restricts this to primary members, and endDate IS NULL stops a member appearing once per historical relationship row.

SELECT
    fm.familyID,
    fm.firstName                AS familyFirstName,
    fm.lastName                 AS familyLastName,
    cm.memberID                 AS clubMembershipNumber,
    cm.firstName                AS memberFirstName,
    cm.lastName                 AS memberLastName,
    cm.DOB,
    fr.relationshipType
FROM FamilyMembers fm
JOIN FamilyRelationship fr ON fr.familyID = fm.familyID AND fr.endDate IS NULL
JOIN ClubMembers        cm ON cm.memberID = fr.memberID
WHERE fm.familyType = 'Primary'
  AND EXISTS (SELECT 1 FROM Game_Participation gp WHERE gp.memberID = cm.memberID)
  AND (SELECT COUNT(DISTINCT fr2.memberID)
         FROM FamilyRelationship fr2
         JOIN Game_Participation gp2 ON gp2.memberID = fr2.memberID
        WHERE fr2.familyID = fm.familyID
          AND fr2.endDate IS NULL) >= 2
ORDER BY fm.firstName ASC, fm.lastName ASC, cm.lastName ASC;
