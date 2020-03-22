SET SEARCH_PATH TO wetworldschema, public;

DROP VIEW IF EXISTS DiveTypes CASCADE;

-- creates a view with all dive types in one column
CREATE VIEW DiveTypes (dive_type) AS VALUES
('open water'), ('cave'), ('deeper than 30');

SELECT DiveTypes.dive_type, count(distinct site_id)
FROM DiveTypes LEFT JOIN MonitorAffiliations
     ON CAST (DiveTypes.dive_type AS dive_type) = MonitorAffiliations.dive_type
GROUP BY DiveTypes.dive_type;