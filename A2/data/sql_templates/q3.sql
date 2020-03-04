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
SELECT * 
FROM AllPairs JOIN OnApril302020
     ON outbound_code=outbound and inbound_code=inbound;
     
-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q3
