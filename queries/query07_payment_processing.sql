-- Query 07: Payment Processing (new payment example)
-- memberID 1006 must exist. The year differs from the previous script.

SET @paymentMemberID = 1006;

INSERT INTO Payments
    (memberID, paymentDate, amount, method,
     membershipYear, installmentNumber)
VALUES
    (@paymentMemberID, '2027-01-15', 45.00, 'Debit', 2027, 1);

SELECT p.paymentID, p.memberID, cm.firstName, cm.lastName,
       p.paymentDate, p.amount, p.method,
       p.membershipYear, p.installmentNumber
FROM Payments AS p
JOIN ClubMembers AS cm ON cm.memberID = p.memberID
ORDER BY p.paymentID
LIMIT 5;

SELECT *
FROM v_MemberDonations
ORDER BY memberID, membershipYear
LIMIT 5;

SELECT memberID, firstName, lastName, memberType, status
FROM v_MemberStatus
ORDER BY memberID
LIMIT 5;
