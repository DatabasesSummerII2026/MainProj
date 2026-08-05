-- Query 02: Personnel Management

INSERT INTO Personnel
    (firstName, lastName, DOB, SSN, medicareNo, telephone,
     address, city, province, postalCode, email, role, mandate, title)
VALUES
    ('Daniel', 'Roy', '1990-09-18', '742-918-365', 'ROY18QX01',
     '514-555-7813', '88 Sherbrooke Street', 'Montreal', 'Quebec',
     'H2X 1C4', 'daniel.roy.test@cscs.ca',
     'Coach', 'Volunteer', NULL);
SET @newPersonnelID = LAST_INSERT_ID();

UPDATE Personnel
SET telephone = '514-555-7820', role = 'Administrator'
WHERE personnelID = @newPersonnelID;

SELECT personnelID, firstName, lastName, DOB, telephone,
       email, role, mandate, title
FROM Personnel
ORDER BY personnelID
LIMIT 5;

-- Safe delete: will not delete a personnel member used as a head coach.
DELETE FROM Personnel
WHERE personnelID = @newPersonnelID
  AND NOT EXISTS (
      SELECT 1 FROM TeamFormations AS tf
      WHERE tf.headCoachID = @newPersonnelID
  );
