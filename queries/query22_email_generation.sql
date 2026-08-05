-- Requirement 22: email generation and the email log.
-- The batch is a stored procedure so it can be called directly.

-- Sessions in the week after Sunday 9 August 2026.
SELECT s.sessionID, s.startDateTime, s.sessionType, s.address, t.teamName,
       CONCAT(p.firstName,' ',p.lastName) AS headCoach, p.email AS coachEmail
FROM Sessions s
JOIN TeamFormations tf ON tf.sessionID  = s.sessionID
JOIN Teams          t  ON t.teamID      = tf.teamID
JOIN Personnel      p  ON p.personnelID = tf.headCoachID
WHERE s.startDateTime >= '2026-08-09'
  AND s.startDateTime <  DATE_ADD('2026-08-09', INTERVAL 7 DAY)
ORDER BY s.startDateTime;

-- Run the weekly batch. Re-running it adds nothing.
CALL sp_GenerateWeeklyEmails('2026-08-09');

-- The log as the description defines it: date, sender location name, receiver, subject, and the first 100 characters of the body.
SELECT el.emailLogID,
       el.emailDateTime            AS emailDate,
       l.name                      AS sender,
       el.receiverEmail            AS receiver,
       el.subject,
       el.bodyPreview
FROM EmailLogs el
JOIN Locations l ON l.locationID = el.senderLocationID
ORDER BY el.emailDateTime, el.emailLogID
LIMIT 15;

-- One full message, showing the body content the description asks for: member name, role, coach name and email, session type, address.
SELECT subject, body FROM EmailLogs ORDER BY emailLogID LIMIT 1\G

-- Calling the batch again adds nothing.
SELECT COUNT(*) AS before_second_run FROM EmailLogs;
CALL sp_GenerateWeeklyEmails('2026-08-09');
SELECT COUNT(*) AS after_second_run FROM EmailLogs;
