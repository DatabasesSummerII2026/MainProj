-- query1: Create/Delete/Edit/Display a Location.  
-- insert
INSERT INTO Locations
    (name, type, address, city, province, postalCode, webAddress, capacity, managerID)
VALUES
    ('Brossard Branch', 'Branch', '100 Main Street',
     'Brossard', 'Quebec', 'J4W 1A1',
     'https://brossard.cscs.ca', 200, NULL);
     
INSERT INTO Location_Phones(locationID, phone)
VALUES
    (LAST_INSERT_ID(), '450-555-1000');     
-- edit    
UPDATE Locations
SET capacity = 250,
    webAddress = 'https://new-brossard.cscs.ca'
WHERE locationID = 7;
-- delete
DELETE FROM Locations
WHERE locationID = 7;
-- display
SELECT l.*, lp.phone
FROM Locations l
LEFT JOIN Location_Phones lp
    ON lp.locationID = l.locationID
LIMIT 10;    