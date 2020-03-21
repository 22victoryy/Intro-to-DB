SET SEARCH_PATH TO wetworldschema, public;

SELECT dive_type, count(distinct site_id)
FROM MonitorAffiliations
GROUP BY dive_type;