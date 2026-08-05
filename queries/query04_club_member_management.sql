-- Query 04: Club Member Management
-- Major/Minor is calculated by v_MemberStatus.

INSERT INTO ClubMembers
    (firstName, lastName, gender, DOB, height, weight, SSN, medicareNo,
     phone, email, address, city, province, postalCode, registrationDate)
VALUES
    ('Noah', 'Tremblay', 'Boys', '2011-07-22', 156.00, 48.50,
     '964-528-173', 'TRE2CD03', '438-555-7815',
     'noah.tremblay.test@example.com', '59 des Prairies Road',
     'Laval', 'Quebec', 'H7N 3K8', '2026-09-01');
SET @newMemberID = LAST_INSERT_ID();

UPDATE ClubMembers
SET phone = '438-555-7822', height = 157.50, weight = 49.00
WHERE memberID = @newMemberID;

SELECT cm.memberID, cm.firstName, cm.lastName, cm.gender, cm.DOB,
       cm.phone, cm.email, vms.memberType, vms.status
FROM ClubMembers AS cm
JOIN v_MemberStatus AS vms ON vms.memberID = cm.memberID
ORDER BY cm.memberID
LIMIT 5;

--  delete
DELETE FROM ClubMembers WHERE memberID = @newMemberID;
