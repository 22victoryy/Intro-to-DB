SET SEARCH_PATH TO wetworldschema, public;

-- get fee for every booking

DROP VIEW IF EXISTS TotalFeesAndDiversPerBooking CASCADE;
DROP VIEW IF EXISTS DiveSiteFullPercentPerDateTime CASCADE;
DROP VIEW IF EXISTS GreaterThanHalfSite CASCADE;
DROP VIEW IF EXISTS LessOrEqualToHalfSite CASCADE;

-- The view contains for every booking the date, time, site it takes place in,
-- the total fees paid for the whole booking including extra fees and the
-- total number of divers including the monitor
CREATE VIEW TotalFeesAndDiversPerBooking AS
SELECT Booking.id AS id,
       MonitorAffiliations.site_id AS site_id,
       date,
       dive_time,
       sum(Booking.price + mask + regulator + fins + computer) AS total_fees,
       count(*)  + 1 AS total_divers
FROM Booking, SubBooking, MonitorAffiliations
WHERE Booking.id = SubBooking.booking_id AND
      MonitorAffiliations.id = Booking.affiliation_id
GROUP BY Booking.id, MonitorAffiliations.site_id, date, dive_time;


-- A view containing how full a site is on a given date time it was booked.
-- If the site was never booked then its not in this view
CREATE VIEW DiveSiteFullPercentPerDateTime AS
SELECT DiveSite.id AS site_id, date, dive_time,
CASE
    WHEN dive_time = 'night' THEN sum(total_divers)/night_capacity
    ELSE sum(total_divers)/day_capacity
END AS full_percent
FROM TotalFeesAndDiversPerBooking JOIN DiveSite
     ON TotalFeesAndDiversPerBooking.site_id = DiveSite.id
GROUP BY DiveSite.id, date, dive_time;

-- Sites that are more than half full on average
CREATE VIEW GreaterThanHalfSite AS
SELECT site_id
FROM DiveSiteFullPercentPerDateTime
GROUP BY site_id
HAVING avg(full_percent) > 0.5;

-- Sites that are less than or equal to half full on average
CREATE VIEW LessOrEqualToHalfSite AS
(SELECT id AS site_id
 FROM DiveSite)
EXCEPT
(SELECT site_id
 FROM GreaterThanHalfSite);

-- Result contains two rows, one for the greater than half with its average fee
-- per dive and one for less than or equal to half with its average fee 
(SELECT 'Greater than half' AS avg_full, avg(total_fees) AS avg_fees_per_dive
 FROM GreaterThanHalfSite, TotalFeesAndDiversPerBooking
 WHERE GreaterThanHalfSite.site_id = TotalFeesAndDiversPerBooking.site_id)
UNION ALL
(SELECT 'Less then or equal to half' AS avg_full,
        avg(total_fees) AS avg_fees_per_dive
 FROM LessOrEqualToHalfSite, TotalFeesAndDiversPerBooking
 WHERE LessOrEqualToHalfSite.site_id = TotalFeesAndDiversPerBooking.site_id);