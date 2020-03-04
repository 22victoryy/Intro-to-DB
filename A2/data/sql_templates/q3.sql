-- Q3. North and South Connections

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO air_travel, public;
DROP TABLE IF EXISTS q3 CASCADE;

CREATE TABLE q3 (
    outbound VARCHAR(30),
    inbound VARCHAR(30),
    direct INT,
    one_con INT,
    two_con INT,
    earliest timestamp
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS OnApril302020 CASCADE;
DROP VIEW IF EXISTS CanadaToUSA CASCADE;
DROP VIEW IF EXISTS AllPairs CASCADE;
DROP VIEW IF EXISTS Direct CASCADE;
DROP VIEW IF EXISTS OneConnections CASCADE;
DROP VIEW IF EXISTS TwoConnections CASCADE;
DROP VIEW IF EXISTS CountDirect CASCADE;
DROP VIEW IF EXISTS CountOneConnection CASCADE;
DROP VIEW IF EXISTS CountTwoConnection CASCADE;


-- Define views for your intermediate steps here:

CREATE VIEW OnApril302020 AS
SELECT id, outbound, inbound, s_dep, s_arv
FROM Flight
WHERE date_part('day', s_dep)   = 30   AND
      date_part('month', s_dep) = 4    AND
      date_part('year', s_dep)  = 2020 AND
      date_part('day', s_arv)   = 30   AND
      date_part('month', s_arv) = 4    AND
      date_part('year', s_arv)  = 2020;

CREATE VIEW CanadaToUSA AS
SELECT a1.code AS outbound_code, a2.code AS inbound_code 
FROM Airport a1, Airport a2
WHERE a1.country='Canada' AND a2.country='USA';

CREATE VIEW AllPairs AS
(SELECT * FROM CanadaToUSA)
UNION
(SELECT inbound_code AS outbound_code, outbound_code AS inbound_code
 FROM CanadaToUSA);

CREATE VIEW Direct AS
SELECT outbound, inbound, f.s_arv as arrival_datetime
FROM AllPairs JOIN OnApril302020 f
     ON outbound_code=outbound and inbound_code=inbound;

CREATE VIEW OneConnection AS
SELECT f1.outbound as outbound, f2.inbound as inbound, f2.s_arv as arrival_datetime
FROM OnApril302020 f1, OnApril302020 f2
WHERE f1.inbound = f2.outbound AND f2.s_dep - f1.s_arv >= '00:30:00'
      AND (f1.outbound, f2.inbound) IN (SELECT * FROM AllPairs);

CREATE VIEW TwoConnection AS
SELECT f1.outbound as outbound, f3.inbound as inbound, f3.s_arv as arrival_datetime
FROM OnApril302020 f1, OnApril302020 f2, OnApril302020 f3
WHERE f1.inbound = f2.outbound AND f2.s_dep - f1.s_arv >= '00:30:00' AND 
      f2.inbound = f3.outbound AND f3.s_dep - f2.s_arv >= '00:30:00'
      AND (f1.outbound, f3.inbound) IN (SELECT * FROM AllPairs);

CREATE VIEW CountDirect AS
SELECT outbound_code AS outbound, inbound_code AS inbound, count(inbound) as c_d
FROM Direct RIGHT JOIN AllPairs 
     ON Direct.outbound = AllPairs.outbound_code
     AND Direct.inbound = AllPairs.inbound_code
GROUP BY outbound_code, inbound_code;

CREATE VIEW CountOneConnection AS
SELECT outbound_code AS outbound, inbound_code AS inbound, count(inbound) as c_1
FROM OneConnection RIGHT JOIN AllPairs 
     ON OneConnection.outbound = AllPairs.outbound_code
     AND OneConnection.inbound = AllPairs.inbound_code
GROUP BY outbound_code, inbound_code;

CREATE VIEW CountTwoConnection AS
SELECT outbound_code AS outbound, inbound_code AS inbound, count(inbound) as c_2
FROM TwoConnection RIGHT JOIN AllPairs 
     ON TwoConnection.outbound = AllPairs.outbound_code
     AND TwoConnection.inbound = AllPairs.inbound_code
GROUP BY outbound_code, inbound_code;

CREATE VIEW AllCounts AS
SELECT *
FROM CountDirect NATURAL JOIN CountOneConnection NATURAL JOIN CountTwoConnection;

CREATE VIEW earliest AS
SELECT inbound_code as inbound, outbound_code as outbound, min(Routes.arrival_datetime) as earliest
FROM AllPairs LEFT JOIN ((SELECT * FROM Direct) 
                          UNION ALL 
                        (SELECT * FROM OneConnection) 
                          UNION ALL 
                        (SELECT * FROM TwoConnection)) Routes
     ON AllPairs.inbound_code=Routes.inbound
     AND AllPairs.outbound_code=Routes.outbound
GROUP BY inbound_code, outbound_code;
-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q3
SELECT a1.city, a2.city, sum(ape.c_d), sum(ape.c_1), sum(ape.c_2), min(ape.earliest)
FROM (SELECT * FROM AllCounts NATURAL JOIN earliest) ape, Airport a1, Airport a2
WHERE ape.outbound=a1.code and ape.inbound=a2.code
GROUP BY a1.city, a2.city;
