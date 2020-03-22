SET SEARCH_PATH TO wetworldschema, public;

DROP VIEW IF EXISTS ALLFEES CASCADE;

CREATE VIEW ALLFEES AS
SELECT price
FROM subbooking INNER JOIN MonitorAffiliations ON (MonitorAffiliations.monitor_id = subbooking.diver_id);

SELECT avg(price), min(price), max(price)
FROM ALLFEES;