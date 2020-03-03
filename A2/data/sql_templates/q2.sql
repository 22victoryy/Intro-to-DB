-- Q2. Refunds!

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO air_travel, public;
DROP TABLE IF EXISTS q2 CASCADE;

CREATE TABLE q2 (
    airline CHAR(2),
    name VARCHAR(50),
    year CHAR(4),
    seat_class seat_class,
    refund REAL
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step CASCADE;

-- date_part('year', booking.datetime)

-- select *,
-- CASE
-- WHEN condition THEN value
-- ELSE
-- END AS attribute_name
-- FROM table;
-- Define views for your intermediate steps here:


-- Your query that answers the question goes below the "insert into" line:
CREATE VIEW delayedflights AS
select *
from flight, departure
where flight.s_dep < departure.datetime;

INSERT INTO q2


-- Gets all the delayed flights

-- select id, price
-- from delayedflights JOIN booked


--  First find late flights
-- 
