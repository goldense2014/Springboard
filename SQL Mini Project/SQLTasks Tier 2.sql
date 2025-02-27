/* Welcome to the SQL mini project. You will carry out this project partly in
the PHPMyAdmin interface, and partly in Jupyter via a Python connection.

This is Tier 2 of the case study, which means that there'll be less guidance for you about how to setup
your local SQLite connection in PART 2 of the case study. This will make the case study more challenging for you: 
you might need to do some digging, and revise the Working with Relational Databases in Python chapter in the previous resource.

Otherwise, the questions in the case study are exactly the same as with Tier 1. 

PART 1: PHPMyAdmin
You will complete questions 1-9 below in the PHPMyAdmin interface. 
Log in by pasting the following URL into your browser, and
using the following Username and Password:

URL: https://sql.springboard.com/
Username: student
Password: learn_sql@springboard

The data you need is in the "country_club" database. This database
contains 3 tables:
    i) the "Bookings" table,
    ii) the "Facilities" table, and
    iii) the "Members" table.

In this case study, you'll be asked a series of questions. You can
solve them using the platform, but for the final deliverable,
paste the code for each solution into this script, and upload it
to your GitHub.

Before starting with the questions, feel free to take your time,
exploring the data, and getting acquainted with the 3 tables. */

Bookings:
bookid
facid
memid
starttime
slots

Facilities:
facid
name
membercost
guestcost
initialoutlay
monthlymaintenance

Members:
memid
surname
firstname
address
zipcode
telephone
recommendedby
joindate


/* QUESTIONS 
/* Q1: Some of the facilities charge a fee to members, but some do not.
Write a SQL query to produce a list of the names of the facilities that do. */

SELECT name
FROM Facilities
WHERE membercost <> 0;

/* Q2: How many facilities do not charge a fee to members? */

5


/* Q3: Write an SQL query to show a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost.
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */

SELECT facid, name, membercost, monthlymaintenance
FROM Facilities
WHERE (membercost <> 0) AND (membercost < 0.2 * `monthlymaintenance`);

/* Q4: Write an SQL query to retrieve the details of facilities with ID 1 and 5.
Try writing the query without using the OR operator. */

SELECT *
FROM Facilities
WHERE facid IN (1,5);


/* Q5: Produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100. Return the name and monthly maintenance of the facilities
in question. */

SELECT name, monthlymaintenance, IF(monthlymaintenance>100, 'expensive', 'cheap') as maintenancecost
FROM Facilities;


/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Try not to use the LIMIT clause for your solution. */

SELECT firstname, surname
FROM Members
WHERE joindate = (
    SELECT MAX(joindate)
    FROM Members
    );

/* Q7: Produce a list of all members who have used a tennis court.
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */

SELECT DISTINCT f.courtname, CONCAT(m.firstname, ' ', m.surname) as membername
 FROM Bookings as b
 INNER JOIN (
     SELECT facid, name as courtname
     FROM Facilities
     WHERE name LIKE 'Tennis Court%'
     ) AS f 
 	ON b.facid = f.facid
 LEFT JOIN (
     SELECT firstname, surname, memid
     FROM Members
     ) AS m 
 	ON m.memid = b.memid
ORDER BY membername;

/* Q8: Produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30. Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */

SELECT DISTINCT
	f.facilityname, 
	CONCAT(m.firstname, ' ', m.surname) AS membername, 
	CASE WHEN b.memid <> 0 THEN f.membercost
    	ELSE f.guestcost
    	END AS cost
FROM Bookings as b
LEFT JOIN Facilities as f
    ON f.facid = b.facid
LEFT JOIN Members as m
	ON m.memid = b.memid
WHERE (DATE(b.starttime) = '2012-09-14') 
HAVING cost > 30
ORDER BY cost DESC;


/* Q9: This time, produce the same result as in Q8, but using a subquery. */

SELECT DISTINCT
	f.facilityname, 
	m.membername, 
	CASE WHEN b.memid <> 0 THEN f.membercost
    	ELSE f.guestcost
    	END AS cost
FROM Bookings as b
LEFT JOIN 
	(SELECT facid, name AS facilityname, membercost, guestcost
     FROM Facilities 
     WHERE (membercost > 30) OR (guestcost > 30)
    ) as f
    ON f.facid = b.facid
LEFT JOIN 
	(SELECT memid, CONCAT(firstname, ' ', surname) AS membername
     FROM Members) as m
	ON m.memid = b.memid
WHERE (DATE(b.starttime) = '2012-09-14') 
ORDER BY cost DESC;


/* PART 2: SQLite

Export the country club data from PHPMyAdmin, and connect to a local SQLite instance from Jupyter notebook 
for the following questions.  

import sqlite3
import pandas as pd
con = sqlite3.connect('../country_club.json')

QUESTIONS:
/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */

query = "
        WITH b AS (SELECT x.facid, x.memid, x.starttime
                    FROM Bookings AS x
                    LEFT JOIN Facilities as f
                    ON x.facid = f.facid
                  )

        SELECT f.facilityname, (SUM(CASE WHEN b.memid <> 0 THEN f.membercost
                                  ELSE f.guestcost
                                  END AS fee) - (MAX(b.starttime)-MIN(b.starttime) * monthlymaintenance)) AS revenue
        FROM b
        GROUP BY revenue, f.facilityname, f.monthlymaintenance
        HAVING revenue < 1000
        ORDER BY revenue;
        "

q11 = pd.read_sql_query(query, con)

print(q10)


/* Q11: Produce a report of members and who recommended them in alphabetic surname,firstname order */


query = "SELECT surname, firstname, recommendedby FROM Members ORDER BY surname, firstname;"

q11 = pd.read_sql_query(query, con)

print(q11)


/* Q12: Find the facilities with their usage by member, but not guests */


query = "SELECT f.name, COUNT(b.memid) AS num_members 
        FROM Bookings AS b
        WHERE memid <> 0 
        LEFT JOIN Facilities AS f
        ON f.facid = b.facid
        GROUP BY f.name 
        ORDER BY num_members DESC;"

q11 = pd.read_sql_query(query, con)

print(q12)


/* Q13: Find the facilities usage by month, but not guests */

query = "
        SELECT f.name, CONCAT(MONTH(starttime), ' ', YEAR(starttime)) AS date, COUNT(starttime) AS usage
        FROM Bookings AS b
        LEFT JOIN Facilities AS f
        ON f.facid = b.facid
        WHERE memid <> 0 
        GROUP BY date, f.name
        ORDER BY usage DESC;
        "

q11 = pd.read_sql_query(query, con)

print(q13)
