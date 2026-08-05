-- Query 03: Family Member Management

INSERT INTO FamilyMembers
    (firstName, lastName, DOB, SSN, medicareNo, phone,
     address, city, province, postalCode, email, familyType)
VALUES
    ('Sophie', 'Gagnon', '1984-11-26', '853-617-294', 'GA26AB02',
     '438-555-7814', '412 Cartier Avenue', 'Laval', 'Quebec', 'H7N 2J6',
     'sophie.gagnon.test@example.com', 'Primary');
SET @newFamilyID = LAST_INSERT_ID();

UPDATE FamilyMembers
SET phone = '438-555-7821', familyType = 'Secondary'
WHERE familyID = @newFamilyID;

SELECT familyID, firstName, lastName, DOB, phone,
       city, province, email, familyType
FROM FamilyMembers
ORDER BY familyID
LIMIT 5;

--  delete
DELETE FROM FamilyMembers WHERE familyID = @newFamilyID;
