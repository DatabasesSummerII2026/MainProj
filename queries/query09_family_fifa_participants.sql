-- Query 9: Family Members with Multiple FIFA Participants
-- This query identifies families that have at least two members
-- who participated in FIFA games.
-- It displays the family information, related club members,
-- and their relationship type within the family.

SELECT 
    fm.FirstName AS family_first_name,
    fm.LastName AS family_last_name,

    -- Club member information
    cm.MemberID,
    cm.FirstName AS member_first_name,
    cm.LastName AS member_last_name,
    cm.DOB,

    -- Relationship between family and club member
    fr.RelationshipType

FROM FamilyMembers fm

-- Join family relationship records to identify family members
JOIN FamilyRelationship fr 
    ON fm.FamilyID = fr.FamilyID

-- Retrieve club member details
JOIN ClubMembers cm 
    ON fr.MemberID = cm.MemberID

-- Retrieve FIFA participation records
JOIN Game_Participation gp 
    ON cm.MemberID = gp.MemberID

WHERE fm.FamilyID IN (

    -- Find families that have at least two different members
    -- participating in FIFA games
    SELECT fr_inner.FamilyID

    FROM FamilyRelationship fr_inner

    JOIN Game_Participation gp_inner 
        ON fr_inner.MemberID = gp_inner.MemberID

    GROUP BY fr_inner.FamilyID

    HAVING COUNT(DISTINCT fr_inner.MemberID) >= 2
)

-- Remove duplicate results caused by multiple participation records
GROUP BY 
    fm.FamilyID,
    fm.FirstName,
    fm.LastName,
    cm.MemberID,
    cm.FirstName,
    cm.LastName,
    cm.DOB,
    fr.RelationshipType

-- Sort results alphabetically by family name
ORDER BY 
    fm.FirstName ASC,
    fm.LastName ASC;
