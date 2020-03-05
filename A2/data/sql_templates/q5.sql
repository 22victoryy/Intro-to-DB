-- Q5. Flight Hopping

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO air_travel, public;
DROP TABLE IF EXISTS q5 CASCADE;

CREATE TABLE q5 (
	destination CHAR(3),
	num_flights INT
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step CASCADE;
DROP VIEW IF EXISTS day CASCADE;
DROP VIEW IF EXISTS n CASCADE;

CREATE VIEW day AS
SELECT day::date as day FROM q5_parameters;
-- can get the given date using: (SELECT day from day)

CREATE VIEW n AS
SELECT n FROM q5_parameters;
-- can get the given number of flights using: (SELECT n from n)
WITH RECURSIVE bitch AS
(SELECT 'YYZ' as inbound, 0 as num_flights, day FROM q5_parameters)
UNION ALL
(SELECT Flight.inbound as inbound, num_flights + 1, Flight.s_arv as s_arv
 FROM Flight, bitch
 WHERE Flight.outbound = bitch.inbound AND
       Flight.s_dep - bitch.s_arv >= '0' AND
	   Flight.s_dep - bitch.s_arv < '24:00:00'
	   AND num_flights = max(num_flights)
	   AND num_flights + 1 <= (SELECT n FROM q5_parameters));

-- HINT: You can answer the question by writing one recursive query below, without any more views.
-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q5
SELECT inbound, num_flights
FROM bitch
WHERE num_flights > 0;
















