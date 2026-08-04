-- Run order: schema.sql, then triggers.sql, then seed.sql.

SET FOREIGN_KEY_CHECKS = 0;

DROP VIEW  IF EXISTS v_MemberStatus;
DROP VIEW  IF EXISTS v_MemberCurrentLocation;
DROP VIEW  IF EXISTS v_MemberDonations;

DROP TABLE IF EXISTS Game_Participation;
DROP TABLE IF EXISTS FIFA_Games;
DROP TABLE IF EXISTS EmailLogs;
DROP TABLE IF EXISTS FormationPlayers;
DROP TABLE IF EXISTS TeamFormations;
DROP TABLE IF EXISTS Sessions;
DROP TABLE IF EXISTS Team_Members;
DROP TABLE IF EXISTS Teams;
DROP TABLE IF EXISTS Member_Hobby;
DROP TABLE IF EXISTS Hobbies;
DROP TABLE IF EXISTS Payments;
DROP TABLE IF EXISTS FamilyRelationship;
DROP TABLE IF EXISTS Family_Location_History;
DROP TABLE IF EXISTS Member_Location_History;
DROP TABLE IF EXISTS Personnel_Assignment;
DROP TABLE IF EXISTS ClubMembers;
DROP TABLE IF EXISTS FamilyMembers;
DROP TABLE IF EXISTS Location_Phones;
DROP TABLE IF EXISTS Locations;
DROP TABLE IF EXISTS Personnel;

SET FOREIGN_KEY_CHECKS = 1;


-- Locations. managerID is nullable because a location can be between managers, and its FK is added by ALTER further down: Locations and Personnel reference each other.
CREATE TABLE Locations (
    locationID   INT AUTO_INCREMENT PRIMARY KEY,
    name         VARCHAR(100) NOT NULL,
    type         ENUM('Head','Branch') NOT NULL,
    address      VARCHAR(200) NOT NULL,
    city         VARCHAR(80)  NOT NULL,
    province     VARCHAR(80)  NOT NULL,
    postalCode   VARCHAR(10)  NOT NULL,
    webAddress   VARCHAR(150) NULL,
    capacity     INT          NOT NULL,
    managerID    INT          NULL,

    UNIQUE KEY uq_Locations_name (name),
    UNIQUE KEY uq_Locations_manager (managerID),   -- a person manages <= 1 location
    CONSTRAINT chk_Locations_capacity CHECK (capacity > 0)
) ENGINE=InnoDB;


-- Location_Phones. The description says a location has "phone number(s)". A repeating attribute inside Locations breaks 1NF, so it gets its own relation. The whole relation is the key.
CREATE TABLE Location_Phones (
    locationID   INT         NOT NULL,
    phone        VARCHAR(20) NOT NULL,

    PRIMARY KEY (locationID, phone),
    CONSTRAINT fk_LocPhone_loc FOREIGN KEY (locationID)
        REFERENCES Locations(locationID) ON DELETE CASCADE
) ENGINE=InnoDB;


-- Personnel. `title` is an extension. The description names a general manager, deputy manager, treasurer and secretary at the head location, but limits `role` to Administrator, Captain, Coach, Assistant Coach and Other.
-- Those four posts all fall under Administrator or Other, so the post goes in `title` instead of being added to the role list.
CREATE TABLE Personnel (
    personnelID  INT AUTO_INCREMENT PRIMARY KEY,
    firstName    VARCHAR(60)  NOT NULL,
    lastName     VARCHAR(60)  NOT NULL,
    DOB          DATE         NOT NULL,
    SSN          VARCHAR(11)  NOT NULL,
    medicareNo   VARCHAR(12)  NULL,
    telephone    VARCHAR(20)  NOT NULL,
    address      VARCHAR(200) NOT NULL,
    city         VARCHAR(80)  NOT NULL,
    province     VARCHAR(80)  NOT NULL,
    postalCode   VARCHAR(10)  NOT NULL,
    email        VARCHAR(120) NOT NULL,
    role         ENUM('Administrator','Captain','Coach','Assistant Coach','Other') NOT NULL,
    mandate      ENUM('Volunteer','Salaried') NOT NULL,
    title        VARCHAR(60)  NULL,

    UNIQUE KEY uq_Personnel_ssn (SSN),
    UNIQUE KEY uq_Personnel_medicare (medicareNo)
) ENGINE=InnoDB;

ALTER TABLE Locations
    ADD CONSTRAINT fk_Locations_manager FOREIGN KEY (managerID)
        REFERENCES Personnel(personnelID) ON DELETE SET NULL;


-- FamilyMembers. familyType separates the primary family member, the one who registered the child, from secondary ones. Report 9 needs it.
CREATE TABLE FamilyMembers (
    familyID     INT AUTO_INCREMENT PRIMARY KEY,
    firstName    VARCHAR(60)  NOT NULL,
    lastName     VARCHAR(60)  NOT NULL,
    DOB          DATE         NOT NULL,
    SSN          VARCHAR(11)  NOT NULL,
    medicareNo   VARCHAR(12)  NULL,
    phone        VARCHAR(20)  NOT NULL,
    address      VARCHAR(200) NOT NULL,
    city         VARCHAR(80)  NOT NULL,
    province     VARCHAR(80)  NOT NULL,
    postalCode   VARCHAR(10)  NOT NULL,
    email        VARCHAR(120) NOT NULL,
    familyType   ENUM('Primary','Secondary') NOT NULL DEFAULT 'Primary',

    UNIQUE KEY uq_Family_ssn (SSN),
    UNIQUE KEY uq_Family_medicare (medicareNo)
) ENGINE=InnoDB;


-- ClubMembers.
-- memberType is deliberately not stored. A stored Major/Minor column is wrong the day a 17-year-old turns 18, and report 14 needs both the current type and the type at registration. 
-- Both are functions of DOB, so storing it would be a transitive dependency, memberID -> DOB -> memberType, and an update anomaly. v_MemberStatus derives both.
-- gender is needed for the rule that a formation cannot mix boys and girls.
CREATE TABLE ClubMembers (
    memberID         INT AUTO_INCREMENT PRIMARY KEY,   -- globally unique across all locations
    firstName        VARCHAR(60)  NOT NULL,
    lastName         VARCHAR(60)  NOT NULL,
    DOB              DATE         NOT NULL,
    gender           ENUM('Boys','Girls') NOT NULL,
    height           DECIMAL(5,2) NULL,                -- cm
    weight           DECIMAL(5,2) NULL,                -- kg
    SSN              VARCHAR(11)  NOT NULL,
    medicareNo       VARCHAR(12)  NULL,
    phone            VARCHAR(20)  NOT NULL,
    email            VARCHAR(120) NOT NULL,
    address          VARCHAR(200) NOT NULL,
    city             VARCHAR(80)  NOT NULL,
    province         VARCHAR(80)  NOT NULL,
    postalCode       VARCHAR(10)  NOT NULL,
    registrationDate DATE         NOT NULL,

    UNIQUE KEY uq_Member_ssn (SSN),
    UNIQUE KEY uq_Member_medicare (medicareNo),
    CONSTRAINT chk_Member_age4 CHECK (registrationDate >= DATE_ADD(DOB, INTERVAL 4 YEAR))
) ENGINE=InnoDB;

ALTER TABLE ClubMembers AUTO_INCREMENT = 1000;   -- readable membership numbers


-- Hobbies and Member_Hobby.
CREATE TABLE Hobbies (
    hobbyID   INT AUTO_INCREMENT PRIMARY KEY,
    hobbyName VARCHAR(60) NOT NULL,
    UNIQUE KEY uq_Hobby_name (hobbyName)
) ENGINE=InnoDB;

CREATE TABLE Member_Hobby (
    memberID INT NOT NULL,
    hobbyID  INT NOT NULL,
    PRIMARY KEY (memberID, hobbyID),
    CONSTRAINT fk_MH_member FOREIGN KEY (memberID) REFERENCES ClubMembers(memberID) ON DELETE CASCADE,
    CONSTRAINT fk_MH_hobby  FOREIGN KEY (hobbyID)  REFERENCES Hobbies(hobbyID)      ON DELETE CASCADE
) ENGINE=InnoDB;


-- Payments. The four-installment cap comes from the UNIQUE key plus the installmentNumber range, and from a trigger on 5.7. Donations are derived in v_MemberDonations, never stored.
CREATE TABLE Payments (
    paymentID        INT AUTO_INCREMENT PRIMARY KEY,
    memberID         INT           NOT NULL,
    paymentDate      DATE          NOT NULL,
    amount           DECIMAL(8,2)  NOT NULL,
    method           ENUM('Cash','Debit','Credit Card') NOT NULL,
    membershipYear   INT           NOT NULL,
    installmentNumber TINYINT      NOT NULL,

    UNIQUE KEY uq_Payment_installment (memberID, membershipYear, installmentNumber),
    CONSTRAINT fk_Pay_member FOREIGN KEY (memberID) REFERENCES ClubMembers(memberID) ON DELETE CASCADE,
    CONSTRAINT chk_Pay_amount      CHECK (amount > 0),
    CONSTRAINT chk_Pay_installment CHECK (installmentNumber BETWEEN 1 AND 4)
) ENGINE=InnoDB;


-- Teams, absorbing BasedAt.
CREATE TABLE Teams (
    teamID     INT AUTO_INCREMENT PRIMARY KEY,
    teamName   VARCHAR(100) NOT NULL,
    gender     ENUM('Boys','Girls') NOT NULL,
    locationID INT NOT NULL,

    UNIQUE KEY uq_Team_name_loc (locationID, teamName),
    CONSTRAINT fk_Team_loc FOREIGN KEY (locationID) REFERENCES Locations(locationID)
) ENGINE=InnoDB;

CREATE TABLE Team_Members (
    teamID    INT  NOT NULL,
    memberID  INT  NOT NULL,
    startDate DATE NOT NULL,
    endDate   DATE NULL,

    PRIMARY KEY (teamID, memberID, startDate),
    CONSTRAINT fk_TM_team   FOREIGN KEY (teamID)   REFERENCES Teams(teamID)          ON DELETE CASCADE,
    CONSTRAINT fk_TM_member FOREIGN KEY (memberID) REFERENCES ClubMembers(memberID)  ON DELETE CASCADE,
    CONSTRAINT chk_TM_dates CHECK (endDate IS NULL OR endDate >= startDate)
) ENGINE=InnoDB;


-- Sessions. A session is the event; a formation is one of the two teams in it.
-- Without this relation there is no way to pair the two sides of a game, which report 18 needs, and nowhere to put the session address, which report 10 needs.
CREATE TABLE Sessions (
    sessionID     INT AUTO_INCREMENT PRIMARY KEY,
    startDateTime DATETIME     NOT NULL,
    address       VARCHAR(200) NOT NULL,   -- may differ from either team's location
    sessionType   ENUM('Training','Game') NOT NULL,

    KEY ix_Sessions_start (startDateTime)
) ENGINE=InnoDB;


-- TeamFormations, absorbing HasFormation, UsesTeam and HeadCoaches.
-- UNIQUE(sessionID, teamID) stops a team facing itself. The at-most-two rule is in triggers.sql.
CREATE TABLE TeamFormations (
    formationID INT AUTO_INCREMENT PRIMARY KEY,
    sessionID   INT NOT NULL,
    teamID      INT NOT NULL,
    headCoachID INT NOT NULL,
    score       INT NULL,                  -- NULL for a future session or a training session

    UNIQUE KEY uq_TF_session_team (sessionID, teamID),
    CONSTRAINT fk_TF_session FOREIGN KEY (sessionID)   REFERENCES Sessions(sessionID) ON DELETE CASCADE,
    CONSTRAINT fk_TF_team    FOREIGN KEY (teamID)      REFERENCES Teams(teamID),
    CONSTRAINT fk_TF_coach   FOREIGN KEY (headCoachID) REFERENCES Personnel(personnelID),
    CONSTRAINT chk_TF_score  CHECK (score IS NULL OR score >= 0)
) ENGINE=InnoDB;


-- FormationPlayers, from AssignedTo. The enum shortens the description's role names. Put this mapping in the report assumptions:
--   "Center back or sweeper"       -> 'Sweeper'
--   "Defending/holding midfielder" -> 'Defending midfielder'
--   "Right midfielder or winger"   -> 'Right winger'
CREATE TABLE FormationPlayers (
    formationID INT NOT NULL,
    memberID    INT NOT NULL,
    playerRole  ENUM(
        'Goalkeeper',
        'Right fullback',
        'Left fullback',
        'Center back',
        'Sweeper',
        'Defending midfielder',
        'Right winger',
        'Central midfielder',
        'Striker',
        'Attacking midfielder',
        'Left winger'
    ) NOT NULL,

    PRIMARY KEY (formationID, memberID),
    CONSTRAINT fk_FP_formation FOREIGN KEY (formationID) REFERENCES TeamFormations(formationID) ON DELETE CASCADE,
    CONSTRAINT fk_FP_member    FOREIGN KEY (memberID)    REFERENCES ClubMembers(memberID)       ON DELETE CASCADE
) ENGINE=InnoDB;


-- The three temporal relations. endDate IS NULL means still there.
CREATE TABLE Personnel_Assignment (
    personnelID INT  NOT NULL,
    locationID  INT  NOT NULL,
    startDate   DATE NOT NULL,
    endDate     DATE NULL,

    PRIMARY KEY (personnelID, locationID, startDate),
    CONSTRAINT fk_PA_personnel FOREIGN KEY (personnelID) REFERENCES Personnel(personnelID) ON DELETE CASCADE,
    CONSTRAINT fk_PA_location  FOREIGN KEY (locationID)  REFERENCES Locations(locationID),
    CONSTRAINT chk_PA_dates CHECK (endDate IS NULL OR endDate >= startDate)
) ENGINE=InnoDB;

CREATE TABLE Member_Location_History (
    memberID   INT  NOT NULL,
    locationID INT  NOT NULL,
    startDate  DATE NOT NULL,
    endDate    DATE NULL,

    PRIMARY KEY (memberID, locationID, startDate),
    CONSTRAINT fk_MLH_member   FOREIGN KEY (memberID)   REFERENCES ClubMembers(memberID) ON DELETE CASCADE,
    CONSTRAINT fk_MLH_location FOREIGN KEY (locationID) REFERENCES Locations(locationID),
    CONSTRAINT chk_MLH_dates CHECK (endDate IS NULL OR endDate >= startDate)
) ENGINE=InnoDB;

CREATE TABLE Family_Location_History (
    familyID   INT  NOT NULL,
    locationID INT  NOT NULL,
    startDate  DATE NOT NULL,
    endDate    DATE NULL,

    PRIMARY KEY (familyID, locationID, startDate),
    CONSTRAINT fk_FLH_family   FOREIGN KEY (familyID)   REFERENCES FamilyMembers(familyID) ON DELETE CASCADE,
    CONSTRAINT fk_FLH_location FOREIGN KEY (locationID) REFERENCES Locations(locationID),
    CONSTRAINT chk_FLH_dates CHECK (endDate IS NULL OR endDate >= startDate)
) ENGINE=InnoDB;


-- FamilyRelationship.
CREATE TABLE FamilyRelationship (
    familyID         INT  NOT NULL,
    memberID         INT  NOT NULL,
    startDate        DATE NOT NULL,
    endDate          DATE NULL,
    relationshipType ENUM('Father','Mother','Grandfather','Grandmother',
                          'Tutor','Partner','Friend','Other') NOT NULL,

    PRIMARY KEY (familyID, memberID, startDate),
    CONSTRAINT fk_FR_family FOREIGN KEY (familyID) REFERENCES FamilyMembers(familyID) ON DELETE CASCADE,
    CONSTRAINT fk_FR_member FOREIGN KEY (memberID) REFERENCES ClubMembers(memberID)   ON DELETE CASCADE,
    CONSTRAINT chk_FR_dates CHECK (endDate IS NULL OR endDate >= startDate)
) ENGINE=InnoDB;


-- EmailLogs. bodyPreview is capped at 100 characters by the description. `body` is an extension so the demo can show the whole message.
CREATE TABLE EmailLogs (
    emailLogID       INT AUTO_INCREMENT PRIMARY KEY,
    emailDateTime    DATETIME     NOT NULL,
    senderLocationID INT          NOT NULL,
    receiverMemberID INT          NOT NULL,
    receiverEmail    VARCHAR(120) NOT NULL,
    subject          VARCHAR(255) NOT NULL,
    bodyPreview      VARCHAR(100) NOT NULL,
    body             TEXT         NULL,      -- extension
    sessionID        INT          NULL,      -- extension: traceability

    CONSTRAINT fk_EL_location FOREIGN KEY (senderLocationID) REFERENCES Locations(locationID),
    CONSTRAINT fk_EL_member   FOREIGN KEY (receiverMemberID) REFERENCES ClubMembers(memberID) ON DELETE CASCADE,
    CONSTRAINT fk_EL_session  FOREIGN KEY (sessionID)        REFERENCES Sessions(sessionID)   ON DELETE SET NULL
) ENGINE=InnoDB;


-- FIFA_Games and Game_Participation.
--
-- These are not Sessions and TeamFormations under another name. A FIFA game is an external event the club records about a member; a session is one the club schedules. Report 13 asks for members never assigned to a formation who have played a FIFA game, which is unanswerable if the two are merged.
--
-- scoreWith and scoreAgainst are integers rather than a '2-1' string so they can be compared in SQL.
CREATE TABLE FIFA_Games (
    gameID       INT AUTO_INCREMENT PRIMARY KEY,
    gameDate     DATE         NOT NULL,
    gameLocation VARCHAR(150) NOT NULL,
    teamWith     VARCHAR(100) NOT NULL,   -- team the member played with
    teamAgainst  VARCHAR(100) NOT NULL,   -- team they played against
    scoreWith    INT          NOT NULL,
    scoreAgainst INT          NOT NULL,

    KEY ix_FIFA_date (gameDate)
) ENGINE=InnoDB;

CREATE TABLE Game_Participation (
    memberID INT NOT NULL,
    gameID   INT NOT NULL,

    PRIMARY KEY (memberID, gameID),
    CONSTRAINT fk_GP_member FOREIGN KEY (memberID) REFERENCES ClubMembers(memberID) ON DELETE CASCADE,
    CONSTRAINT fk_GP_game   FOREIGN KEY (gameID)   REFERENCES FIFA_Games(gameID)    ON DELETE CASCADE
) ENGINE=InnoDB;


-- Views.
-- Current location of every club member (endDate IS NULL = current).
CREATE VIEW v_MemberCurrentLocation AS
SELECT mlh.memberID,
       mlh.locationID,
       l.name AS locationName
FROM   Member_Location_History mlh
JOIN   Locations l ON l.locationID = mlh.locationID
WHERE  mlh.endDate IS NULL;


-- Age, major/minor, active/inactive and current location, all derived.
--
-- The active rule is an assumption worth stating in the report: a member is inactive when the previous calendar year's fees were not paid in full. A member who registered this year has no previous year and is active. The fee for year Y follows the member's age on 1 January of Y.
CREATE VIEW v_MemberStatus AS
SELECT
    cm.memberID,
    cm.firstName,
    cm.lastName,
    cm.DOB,
    cm.gender,
    cm.phone,
    cm.email,
    cm.registrationDate,
    TIMESTAMPDIFF(YEAR, cm.DOB, CURDATE())                          AS age,
    CASE WHEN TIMESTAMPDIFF(YEAR, cm.DOB, CURDATE()) >= 18
         THEN 'Major' ELSE 'Minor' END                              AS memberType,
    CASE WHEN TIMESTAMPDIFF(YEAR, cm.DOB, cm.registrationDate) >= 18
         THEN 'Major' ELSE 'Minor' END                              AS typeAtRegistration,
    vcl.locationID                                                  AS currentLocationID,
    vcl.locationName                                                AS currentLocationName,
    CASE
        WHEN YEAR(cm.registrationDate) >= YEAR(CURDATE()) THEN 'Active'
        WHEN (SELECT COALESCE(SUM(p.amount), 0)
                FROM Payments p
               WHERE p.memberID = cm.memberID
                 AND p.membershipYear = YEAR(CURDATE()) - 1)
             >= (CASE WHEN TIMESTAMPDIFF(YEAR, cm.DOB,
                            MAKEDATE(YEAR(CURDATE()) - 1, 1)) >= 18
                      THEN 200 ELSE 100 END)
        THEN 'Active' ELSE 'Inactive'
    END                                                             AS status
FROM ClubMembers cm
LEFT JOIN v_MemberCurrentLocation vcl ON vcl.memberID = cm.memberID;


-- Donations: anything paid above the annual fee for that membership year.
CREATE VIEW v_MemberDonations AS
SELECT
    p.memberID,
    p.membershipYear,
    SUM(p.amount)                                   AS totalPaid,
    CASE WHEN TIMESTAMPDIFF(YEAR, cm.DOB, MAKEDATE(p.membershipYear, 1)) >= 18
         THEN 200 ELSE 100 END                      AS feeOwed,
    GREATEST(SUM(p.amount) -
             CASE WHEN TIMESTAMPDIFF(YEAR, cm.DOB, MAKEDATE(p.membershipYear, 1)) >= 18
                  THEN 200 ELSE 100 END, 0)         AS donation
FROM Payments p
JOIN ClubMembers cm ON cm.memberID = p.memberID
GROUP BY p.memberID, p.membershipYear, cm.DOB;
