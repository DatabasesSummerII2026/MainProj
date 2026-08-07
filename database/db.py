import mysql.connector


def get_connection():

    connection = mysql.connector.connect(
        host="wec353.encs.concordia.ca",
        user="wec353_1",
        password="comp2026",
        database="wec353_1"
    )

    return connection



def get_team_formations():

    conn = get_connection()

    cursor = conn.cursor(dictionary=True)

    cursor.execute("""
        SELECT

            TF.formationID,

            T.teamName,

            T.gender,

            CONCAT(P.firstName, ' ', P.lastName) 
            AS headCoach,

            S.startDateTime,

            S.sessionType,

            S.address,

            TF.score


        FROM TeamFormations TF


        JOIN Teams T
        ON TF.teamID = T.teamID


        JOIN Personnel P
        ON TF.headCoachID = P.personnelID


        JOIN Sessions S
        ON TF.sessionID = S.sessionID


        ORDER BY S.startDateTime ASC

    """)


    formations = cursor.fetchall()


    cursor.close()
    conn.close()


    return formations




def create_team_formation(
    sessionID,
    teamID,
    headCoachID,
    score
):

    conn = get_connection()

    cursor = conn.cursor()


    cursor.execute("""
        INSERT INTO TeamFormations
        (
            sessionID,
            teamID,
            headCoachID,
            score
        )

        VALUES
        (
            %s,
            %s,
            %s,
            %s
        )

    """,
    (
        sessionID,
        teamID,
        headCoachID,
        score
    ))


    conn.commit()


    cursor.close()
    conn.close()




def get_team_members():

    conn = get_connection()

    cursor = conn.cursor(dictionary=True)


    cursor.execute("""
        SELECT

            tm.teamID,
            tm.memberID,
            tm.startDate,
            tm.endDate,

            cm.firstName,
            cm.lastName,

            t.teamName,
            t.gender


        FROM Team_Members tm


        JOIN ClubMembers cm
        ON tm.memberID = cm.memberID


        JOIN Teams t
        ON tm.teamID = t.teamID


        ORDER BY tm.startDate DESC

    """)


    assignments = cursor.fetchall()


    cursor.close()
    conn.close()


    return assignments

def get_payments():

    conn = get_connection()

    cursor = conn.cursor(dictionary=True)


    cursor.execute("""
        SELECT

            p.paymentID,

            CONCAT(
                cm.firstName,
                ' ',
                cm.lastName
            ) AS memberName,

            p.paymentDate,

            p.amount,

            p.method,

            p.membershipYear,

            p.installmentNumber


        FROM Payments p


        JOIN ClubMembers cm

        ON p.memberID = cm.memberID


        ORDER BY p.paymentDate DESC

    """)


    payments = cursor.fetchall()


    cursor.close()
    conn.close()


    return payments

def get_member_reports():

    conn = get_connection()

    cursor = conn.cursor(dictionary=True)


    cursor.execute("""
        SELECT

            COUNT(*) AS totalMembers,

            SUM(
                CASE 
                    WHEN gender='Boys' 
                    THEN 1 
                    ELSE 0 
                END
            ) AS boys,

            SUM(
                CASE 
                    WHEN gender='Girls' 
                    THEN 1 
                    ELSE 0 
                END
            ) AS girls


        FROM ClubMembers

    """)


    report = cursor.fetchone()


    cursor.close()
    conn.close()


    return report
def get_formation_reports():

    conn = get_connection()

    cursor = conn.cursor(dictionary=True)


    cursor.execute("""
        SELECT

            COUNT(*) AS totalFormations,

            AVG(score) AS averageScore,

            MAX(score) AS highestScore


        FROM TeamFormations

    """)


    summary = cursor.fetchone()


    cursor.execute("""
        SELECT

            T.teamName,

            T.gender,

            CONCAT(
                P.firstName,
                ' ',
                P.lastName
            ) AS coach,

            S.sessionType,

            S.startDateTime,

            TF.score


        FROM TeamFormations TF


        JOIN Teams T

        ON TF.teamID = T.teamID


        JOIN Personnel P

        ON TF.headCoachID = P.personnelID


        JOIN Sessions S

        ON TF.sessionID = S.sessionID


        ORDER BY TF.score DESC

    """)


    details = cursor.fetchall()


    cursor.close()
    conn.close()


    return {
        "summary": summary,
        "details": details
    }

def get_fifa_reports():

    conn = get_connection()

    cursor = conn.cursor(dictionary=True)


    # Summary statistics
    cursor.execute("""
        SELECT

            COUNT(*) AS totalGames,

            SUM(
                CASE 
                    WHEN scoreWith > scoreAgainst 
                    THEN 1 
                    ELSE 0 
                END
            ) AS wins,


            SUM(
                CASE 
                    WHEN scoreWith = scoreAgainst 
                    THEN 1 
                    ELSE 0 
                END
            ) AS draws,


            SUM(
                CASE 
                    WHEN scoreWith < scoreAgainst 
                    THEN 1 
                    ELSE 0 
                END
            ) AS losses


        FROM FIFA_Games

    """)


    summary = cursor.fetchone()



    # Game details

    cursor.execute("""
        SELECT

            gameDate,

            gameLocation,

            teamWith,

            teamAgainst,

            scoreWith,

            scoreAgainst


        FROM FIFA_Games


        ORDER BY gameDate DESC

    """)


    games = cursor.fetchall()


    cursor.close()
    conn.close()


    return {
        "summary": summary,
        "games": games
    }

def get_email_logs():

    conn = get_connection()

    cursor = conn.cursor(dictionary=True)

    cursor.execute("""
        SELECT

            EL.emailLogID,

            EL.emailDateTime,

            EL.senderLocationID,

            EL.receiverMemberID,

            EL.receiverEmail,

            EL.subject,

            EL.bodyPreview,

            EL.sessionID


        FROM EmailLogs EL


        ORDER BY EL.emailDateTime DESC

    """)


    logs = cursor.fetchall()


    cursor.close()
    conn.close()


    return logs


def get_formation_players():

    conn = get_connection()

    cursor = conn.cursor(dictionary=True)


    cursor.execute("""
        SELECT

            FP.formationID,

            CONCAT(
                CM.firstName,
                ' ',
                CM.lastName
            ) AS playerName,

            FP.playerRole,

            T.teamName


        FROM FormationPlayers FP


        JOIN ClubMembers CM

        ON FP.memberID = CM.memberID


        JOIN TeamFormations TF

        ON FP.formationID = TF.formationID


        JOIN Teams T

        ON TF.teamID = T.teamID


        ORDER BY FP.formationID

    """)


    players = cursor.fetchall()


    cursor.close()
    conn.close()


    return players

def get_family_relationships():

    conn = get_connection()

    cursor = conn.cursor(dictionary=True)


    cursor.execute("""
        SELECT

            FR.familyID,

            CONCAT(
                FM.firstName,
                ' ',
                FM.lastName
            ) AS familyName,


            CONCAT(
                CM.firstName,
                ' ',
                CM.lastName
            ) AS memberName,


            FR.relationshipType,

            FR.startDate,

            FR.endDate


        FROM FamilyRelationship FR


        JOIN FamilyMembers FM

        ON FR.familyID = FM.familyID


        JOIN ClubMembers CM

        ON FR.memberID = CM.memberID


        ORDER BY FR.startDate DESC

    """)


    relationships = cursor.fetchall()


    cursor.close()
    conn.close()


    return relationships
def get_hobbies():

    conn = get_connection()

    cursor = conn.cursor(dictionary=True)


    cursor.execute("""
        SELECT

            hobbyID,
            hobbyName

        FROM Hobbies

        ORDER BY hobbyName ASC

    """)


    hobbies = cursor.fetchall()


    cursor.close()
    conn.close()


    return hobbies

def get_member_hobbies():

    conn = get_connection()

    cursor = conn.cursor(dictionary=True)


    cursor.execute("""
        SELECT

            MH.memberID,

            CONCAT(
                CM.firstName,
                ' ',
                CM.lastName
            ) AS memberName,


            H.hobbyName


        FROM Member_Hobby MH


        JOIN ClubMembers CM

        ON MH.memberID = CM.memberID


        JOIN Hobbies H

        ON MH.hobbyID = H.hobbyID


        ORDER BY CM.firstName ASC

    """)


    hobbies = cursor.fetchall()


    cursor.close()
    conn.close()


    return hobbies
def get_personnel_assignments():

    conn = get_connection()

    cursor = conn.cursor(dictionary=True)


    cursor.execute("""
        SELECT

            PA.personnelID,

            CONCAT(
                P.firstName,
                ' ',
                P.lastName
            ) AS personnelName,


            P.role,


            L.locationID,

            L.address,

            L.city,

            L.province,


            PA.startDate,

            PA.endDate


        FROM Personnel_Assignment PA


        JOIN Personnel P

        ON PA.personnelID = P.personnelID


        JOIN Locations L

        ON PA.locationID = L.locationID


        ORDER BY PA.startDate DESC

    """)


    assignments = cursor.fetchall()


    cursor.close()
    conn.close()


    return assignments

def get_latest_email_log():

    conn = get_connection()

    cursor = conn.cursor(dictionary=True)

    cursor.execute("""
        SELECT
            emailLogID,
            emailDateTime,
            subject,
            body
        FROM EmailLogs
        ORDER BY emailLogID DESC
        LIMIT 1
    """)

    log = cursor.fetchone()

    cursor.close()
    conn.close()

    return log