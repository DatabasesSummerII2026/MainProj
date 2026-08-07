from flask import Flask, render_template, request, redirect, url_for, flash
from database.db import *
from flask import request


app = Flask(__name__)
app.secret_key = 'csc_1921_secret_key'


# Database connection configuration
def get_connection():
    connection = mysql.connector.connect(
        host="wec353.encs.concordia.ca",
        user="wec353_1",
        password="comp2026",
        database="wec353_1"
    )
    return connection


@app.route('/')
def index():
    return render_template('index.html')


# ===== LOCATIONS PAGE =====

@app.route('/locations')
def show_locations():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)  # Use dictionary cursor to access database fields by column names

    try:
        # Use LEFT JOIN and GROUP_CONCAT to retrieve all phone numbers associated with each location
        query = """
        SELECT l.*, GROUP_CONCAT(p.phone SEPARATOR ', ') AS phones
        FROM Locations l
        LEFT JOIN Location_Phones p 
        ON l.locationID = p.locationID
        GROUP BY l.locationID
        ORDER BY l.locationID ASC
        """

        cursor.execute(query)
        locations = cursor.fetchall()
        print("DEBUG LOCATIONS:")
        print(locations)
    except Exception as e:
        print(f"Error fetching locations: {e}")
        locations = []

    finally:
        cursor.close()
        conn.close()

    return render_template('locations.html', locations=locations)


@app.route('/locations/add', methods=['POST'])
def add_location():

    if request.method == 'POST':

        # Retrieve form data from the frontend
        name = request.form.get('name')
        loc_type = request.form.get('type')
        capacity = request.form.get('capacity')
        address = request.form.get('address')
        city = request.form.get('city')
        province = request.form.get('province')
        postal_code = request.form.get('postalCode')
        phone = request.form.get('phone')
        web_address = request.form.get('webAddress')
        manager_id = request.form.get('managerID') or None


        conn = get_connection()
        cursor = conn.cursor()

        try:

            # Insert location information into the Locations table (including managerID)
            insert_loc = """
                INSERT INTO Locations 
                (name, type, capacity, address, city, province, postalCode, webAddress, managerID)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            """

            cursor.execute(
                insert_loc,
                (
                    name,
                    loc_type,
                    capacity,
                    address,
                    city,
                    province,
                    postal_code,
                    web_address,
                    manager_id
                )
            )


            # Retrieve the ID of the newly inserted location
            loc_id = cursor.lastrowid


            # If a phone number is provided, insert it into the Location_Phones table
            if phone and phone.strip():
                insert_phone = """
                    INSERT INTO Location_Phones (locationID, phone)
                    VALUES (%s, %s)
                """
                cursor.execute(insert_phone, (loc_id, phone.strip()))


            conn.commit()
            flash('Location added successfully!', 'success')


        except Exception as e:
            conn.rollback()
            print(f"Error adding location: {e}")
            flash(f'Failed to add location: {e}', 'danger')


        finally:
            cursor.close()
            conn.close()


    return redirect(url_for('show_locations'))



# ===== MEMBERS PAGE =====

@app.route('/members')
def show_members():

    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    try:

        query = """
        SELECT
            memberID,
            firstName,
            lastName,
            DOB,
            gender,
            height,
            weight,
            phone,
            email,
            city,
            province,
            registrationDate
        FROM ClubMembers
        ORDER BY memberID
        LIMIT 50
        """

        cursor.execute(query)

        members = cursor.fetchall()


    except Exception as e:

        print("ERROR MEMBERS:", e)
        members = []


    finally:

        cursor.close()
        conn.close()


    return render_template(
        'members.html',
        members=members
    )

# ===== TEAMS PAGE =====

@app.route('/teams')
def show_teams():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    try:
        query = """
        SELECT 
            t.teamID,
            t.teamName,
            t.gender,
            l.name AS locationName
        FROM Teams t
        LEFT JOIN Locations l
        ON t.locationID = l.locationID
        ORDER BY t.teamID ASC
        """

        cursor.execute(query)
        teams = cursor.fetchall()

        print("DEBUG TEAMS:")
        print(teams)

    except Exception as e:
        print(f"Error fetching teams: {e}")
        teams = []

    finally:
        cursor.close()
        conn.close()

    return render_template('teams.html', teams=teams)
@app.route('/personnel')
def show_personnel():

    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    try:

        query = """
        SELECT
            personnelID,
            firstName,
            lastName,
            DOB,
            telephone,
            email,
            role,
            mandate,
            title,
            city,
            province
        FROM Personnel
        ORDER BY personnelID
        LIMIT 50
        """

        cursor.execute(query)

        personnel = cursor.fetchall()

        print("DEBUG PERSONNEL:")
        print(personnel)


    except Exception as e:

        print("ERROR:", e)
        personnel = []


    finally:

        cursor.close()
        conn.close()


    return render_template(
        'personnel.html',
        personnel=personnel
    )

@app.route('/family_members')
def show_family_members():

    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    try:

        query = """
        SELECT
            familyID,
            firstName,
            lastName,
            DOB,
            phone,
            email,
            familyType,
            city,
            province
        FROM FamilyMembers
        ORDER BY familyID
        LIMIT 50
        """

        cursor.execute(query)

        family_members = cursor.fetchall()

        print("DEBUG FAMILY MEMBERS:")
        print(family_members)


    except Exception as e:

        print("ERROR:", e)
        family_members = []


    finally:

        cursor.close()
        conn.close()


    return render_template(
        'family_members.html',
        family_members=family_members
    )
@app.route('/family_members/add', methods=['GET', 'POST'])
def add_family_member():

    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    if request.method == 'POST':

        try:

            query = """
            INSERT INTO FamilyMembers
            (
                firstName,
                lastName,
                DOB,
                SSN,
                medicareNo,
                phone,
                address,
                city,
                province,
                postalCode,
                email,
                familyType
            )
            VALUES
            (
                %s,%s,%s,%s,%s,%s,
                %s,%s,%s,%s,%s,%s
            )
            """


            values = (
                request.form['firstName'],
                request.form['lastName'],
                request.form['DOB'],
                request.form['SSN'],
                request.form['medicareNo'],
                request.form['phone'],
                request.form['address'],
                request.form['city'],
                request.form['province'],
                request.form['postalCode'],
                request.form['email'],
                request.form['familyType']
            )


            cursor.execute(query, values)
            conn.commit()


            return redirect(url_for('show_family_members'))


        except Exception as e:

            print("ADD FAMILY ERROR:", e)



    cursor.close()
    conn.close()


    return render_template(
        'add_family_member.html'
    )
@app.route('/formations')
def show_formations():

    formations = get_team_formations()

    return render_template(
        "formations.html",
        formations=formations
    )

@app.route('/formations/add', methods=['GET','POST'])
def add_formation():

    if request.method == 'POST':

        sessionID = request.form['sessionID']
        teamID = request.form['teamID']
        headCoachID = request.form['headCoachID']
        score = request.form['score']

        create_team_formation(
            sessionID,
            teamID,
            headCoachID,
            score
        )

        return redirect(url_for('show_formations'))


    return render_template(
        "add_formation.html"
    )
@app.route('/assign-member')
def assign_member():

    assignments = get_team_members()

    return render_template(
        "assign_member.html",
        assignments=assignments
    )
@app.route('/payments')
def payments():

    payments = get_payments()

    return render_template(
        "payments.html",
        payments=payments
    )
@app.route('/member-reports')
def member_reports():

    report = get_member_reports()


    return render_template(
        "member_reports.html",
        report=report
    )
@app.route('/formation-reports')
def formation_reports():

    report = get_formation_reports()


    return render_template(
        "formation_reports.html",
        report=report
    )

@app.route('/fifa-reports')
def fifa_reports():

    report = get_fifa_reports()


    return render_template(
        "fifa_reports.html",
        report=report
    )

@app.route('/email_logs')
def show_email_logs():

    logs = get_email_logs()

    return render_template(
        "email_logs.html",
        logs=logs
    )

@app.route('/formation_players')
def show_formation_players():

    players = get_formation_players()


    return render_template(
        "formation_players.html",
        players=players
    )
@app.route('/family_relationships')
def show_family_relationships():

    relationships = get_family_relationships()


    return render_template(
        "family_relationships.html",
        relationships=relationships
    )
@app.route('/hobbies')
def show_hobbies():

    hobbies = get_hobbies()


    return render_template(
        "hobbies.html",
        hobbies=hobbies
    )

@app.route('/member_hobbies')
def show_member_hobbies():

    hobbies = get_member_hobbies()


    return render_template(
        "member_hobbies.html",
        hobbies=hobbies
    )
@app.route('/personnel_assignments')
def show_personnel_assignments():

    assignments = get_personnel_assignments()

    return render_template(
        "personnel_assignments.html",
        assignments=assignments
    )

@app.route('/trigger_demo')
def trigger_demo():

    log = get_latest_email_log()

    return render_template(
        "trigger_demo.html",
        log=log
    )


if __name__ == '__main__':
    app.run(debug=True, port=5000)

