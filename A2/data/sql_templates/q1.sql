-- Q1. Airlines

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO air_travel, public;
DROP TABLE IF EXISTS q1 CASCADE;

CREATE TABLE q1 (
    pass_id INT,
    name VARCHAR(100),
    airlines INT
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
DROP VIEW IF EXISTS finished_flights CASCADE;


-- Define views for your intermediate steps here:


-- Your query that answers the question goes below the "insert into" line:

CREATE VIEW finished_flights AS
select pass_id, airline as airlines
from Flight, Departure, Booking
where Flight.id = Departure.flight_id and Booking.flight_id = Departure.flight_id;

INSERT INTO q1
SELECT id, firstname || ' ' ||surname as name, count(distinct airlines)
FROM Passenger LEFT JOIN finished_flights ON pass_id=id
group by id, name;

--  done --





