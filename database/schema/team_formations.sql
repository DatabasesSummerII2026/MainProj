CREATE TABLE Team_Formations
(
    FormationID INT AUTO_INCREMENT PRIMARY KEY,

    TeamID INT NOT NULL,

    LocationID INT NOT NULL,

    CoachID INT NOT NULL,

    StartTime DATETIME NOT NULL,

    SessionType ENUM('Training','Game') NOT NULL,

    Score INT NULL,

    FOREIGN KEY (TeamID)
        REFERENCES Teams(TeamID),

    FOREIGN KEY (LocationID)
        REFERENCES Locations(LocationID),

    FOREIGN KEY (CoachID)
        REFERENCES Personnel(PersonnelID)
);

