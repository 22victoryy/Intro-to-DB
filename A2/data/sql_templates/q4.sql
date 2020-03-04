-- Q4. Plane Capacity Histogram

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO air_travel, public;
DROP TABLE IF EXISTS q4 CASCADE;


DROP VIEW IF EXISTS departedplanes CASCADE;
DROP VIEW IF EXISTS departed CASCADE;
DROP VIEW IF EXISTS p CASCADE;
DROP VIEW IF EXISTS very_low CASCADE;
DROP VIEW IF EXISTS low CASCADE;
DROP VIEW IF EXISTS fair CASCADE;
DROP VIEW IF EXISTS normal CASCADE;
DROP VIEW IF EXISTS high CASCADE;
DROP VIEW IF EXISTS contingency CASCADE;



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
SELECT departedplanes.id as id, airline as air, plane as tail, count(booking.id) as booked
FROM departedplanes
LEFT JOIN booking
ON departedplanes.flight_id = booking.flight_id
GROUP BY departedplanes.id,airline,plane;

CREATE VIEW p AS
SELECT Plane.airline as air, Plane.tail_number as tail, cast(booked AS decimal)/(capacity_economy+Capacity_business+Capacity_first) as percentage
FROM departed RIGHT JOIN Plane ON Plane.tail_number=departed.tail;

CREATE VIEW very_low AS
Select air, tail,
CASE
    WHEN p.percentage < 0.2 THEN 1
    ELSE 0
END as a
FROM p;

CREATE VIEW low AS
Select air, tail,
CASE
    WHEN p.percentage >= 0.2 and p.percentage < 0.4 THEN 1
    ELSE 0
END as b
FROM p;

CREATE VIEW  fair AS
Select air, tail,
CASE
    WHEN p.percentage >= 0.4 and p.percentage < 0.6 THEN 1
    ELSE 0
END as c 
FROM p;


CREATE VIEW normal AS
Select air, tail,
CASE
    WHEN p.percentage >= 0.6 and p.percentage < 0.8 THEN 1
    ELSE 0
END as d
FROM p;


CREATE VIEW high AS
Select air, tail,
CASE
    WHEN p.percentage >= 0.8 THEN 1
    ELSE 0
END as e
FROM p;

CREATE VIEW contingency AS
select very_low.air, very_low.tail, sum(a), sum(b), sum(c), sum(d), sum(e)
from very_low, low, fair, normal, high
WHERE very_low.air=low.air and low.air=fair.air and fair.air=normal.air and normal.air=high.air and
very_low.tail=low.tail and low.tail=fair.tail and fair.tail=normal.tail and normal.tail=high.tail
GROUP BY very_low.air, very_low.tail;






-- fuck 


-- Your query that answers the question goes below the "insert into" line:
-- INSERT INTO q4


