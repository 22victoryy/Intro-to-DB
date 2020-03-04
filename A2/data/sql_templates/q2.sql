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
DROP VIEW IF EXISTS delayedflights CASCADE;
DROP VIEW IF EXISTS delayedflightsType CASCADE;

-- Define views for your intermediate steps here:

-- Your query that answers the question goes below the "insert into" line:
CREATE VIEW delayedflights AS
select id, airline, outbound, inbound, date_part('year', flight.s_dep) AS year,
       departure.datetime - flight.s_dep as dep_interval,
       arrival.datetime - flight.s_arv as arv_interval
from flight, arrival, departure
where flight.id = arrival.flight_id and
      flight.id = departure.flight_id and
      flight.s_dep < departure.datetime;

CREATE VIEW delayedflightsType AS
select id, airline, year, dep_interval,
CASE
    WHEN a1.country = a2.country THEN 'domestic'
    WHEN a1.country <> a2.country THEN 'international'
    ELSE NULL
END AS kind
from delayedflights, airport a1, airport a2
where outbound=a1.code and inbound=a2.code and
      dep_interval*0.5 < arv_interval;

CREATE VIEW thirtyfivepercenters AS
SELECT id, airline, year, 0.35 as multiple
FROM delayedflightsType
WHERE (kind='international' and dep_interval >= '7:00:00' and dep_interval < '12:00:00') or
      (kind='domestic' and dep_interval >= '4:00:00' and dep_interval < '10:00:00');


CREATE VIEW fiftypercenters AS
SELECT id, airline, year, 0.5 as multiple
FROM delayedflightsType
WHERE (kind='international' and dep_interval > '10:00:00') or
      (kind='domestic' and dep_interval > '12:00:00');

CREATE VIEW total AS
SELECT SUM(booking.price)
FROM thirtyfivepercenters UNION fiftypercenters INNER JOIN booking;

INSERT INTO q2


-- Gets all the delayed flights

-- select id, price
-- from delayedflights JOIN booked


--  First find late flights
-- 
