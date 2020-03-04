-- Q4. Plane Capacity Histogram

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO air_travel, public;
DROP TABLE IF EXISTS q4 CASCADE;

CREATE TABLE q4 (
	airline CHAR(2),
	tail_number CHAR(5),
	very_low INT,
	low INT,
	fair INT,
	normal INT,
	high INT
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step CASCADE;

-- Define views for your intermediate steps here:
CREATE VIEW departedplanes AS
SELECT *
FROM departure, flight
WHERE departure.flight_id = flight.id;

CREATE VIEW departed AS
SELECT departedplanes.id as id, airline as air, plane as tail, count(*) as booked
FROM departedplanes
INNER JOIN booking
ON departedplanes.flight_id = booking.flight_id
GROUP BY departedplanes.id,airline,plane;

CREATE VIEW p AS
SELECT id, air, tail, booked/(capacity_economy+Capacity_business+Capacity_first) as percentage
FROM departed RIGHT JOIN Plane ON Plane.tail_number=departed.tail;

CREATE VIEW very_low AS
Select air, tail, count(*) as a
FROM p
WHERE p.percentage < 0.2
GROUP BY air, tail;

CREATE VIEW low AS
Select air, tail, count(*) as b
FROM p
WHERE p.percentage >= 0.2 and p.percentage < 0.4
GROUP BY air, tail;

CREATE VIEW  fair AS
Select air, tail, count(*) as c
FROM p
WHERE p.percentage >= 0.4 and p.percentage < 0.6
GROUP BY air, tail;


CREATE VIEW normal AS
Select air, tail, count(*) as d
FROM p
WHERE p.percentage >= 0.6 and p.percentage < 0.8
GROUP BY air, tail;


CREATE VIEW high AS
Select air, tail, count(*) as e
FROM p
WHERE p.percentage >= 0.8
GROUP BY air, tail;

CREATE VIEW contingency AS
select very_low.air, very_low.tail, a, b, c, d, e
from very_low, low, fair, normal, high
WHERE very_low.air=low.air and low.air=fair.air and fair.air=normal.air and normal.air=high.air and
very_low.tail=low.tail and low.tail=fair.tail and fair.tail=normal.tail and normal.tail=high.tail;








-- Your query that answers the question goes below the "insert into" line:
-- INSERT INTO q4


