CREATE TABLE Formation_Players
(
    FormationID INT,
    MemberID INT,

    PlayerRole ENUM(
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
    ),

    PRIMARY KEY
    (
        FormationID,
        MemberID
    ),

    FOREIGN KEY(FormationID)
        REFERENCES Team_Formations(FormationID),

    FOREIGN KEY(MemberID)
        REFERENCES ClubMembers(MemberID)
);
