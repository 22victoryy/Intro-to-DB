SET SEARCH_PATH TO wetworldschema, public;

DROP VIEW IF EXISTS AvgSiteRating CASCADE;
DROP VIEW IF EXISTS AvgMonitorRating CASCADE;
DROP VIEW IF EXISTS BetterMonitors CASCADE;
DROP VIEW IF EXISTS BetterMonitorsAvgFee CASCADE;

-- For every site that has been rated the view contains its average rating
CREATE VIEW AvgSiteRating AS
SELECT MonitorAffiliations.site_id AS site_id,
       avg(SiteRating.rating) AS avg_rating 
FROM SiteRating, Booking, MonitorAffiliations
WHERE SiteRating.booking_id = Booking.id AND
      Booking.affiliation_id = MonitorAffiliations.id
GROUP BY MonitorAffiliations.site_id;

-- For every monitor that has been rated the view contains their average rating
CREATE VIEW AvgMonitorRating AS
SELECT MonitorAffiliations.monitor_id AS monitor_id,
       avg(MonitorRating.rating) AS avg_rating 
FROM MonitorRating, Booking, MonitorAffiliations
WHERE MonitorRating.id = Booking.id AND
      Booking.affiliation_id = MonitorAffiliations.id
GROUP BY MonitorAffiliations.monitor_id;

-- The view contains the monitor ids of monitors who have a higher average
-- rating than all of the sites they monitor in
CREATE VIEW BetterMonitors AS
SELECT monitor_id
FROM AvgMonitorRating
WHERE avg_rating > ALL (SELECT avg_rating
                        FROM AvgSiteRating, MonitorAffiliations MA
                        WHERE AvgSiteRating.site_id = MA.site_id
                        AND MA.monitor_id = AvgMonitorRating.monitor_id);

-- The view contains the monitor id and their average fee for monitors who have
-- a higher average rating than all of the sites they monitor in
CREATE VIEW BetterMonitorsAvgFee AS
SELECT BetterMonitors.monitor_id, avg(MonitorAffiliations.price) AS avg_fees
FROM BetterMonitors, MonitorAffiliations
WHERE BetterMonitors.monitor_id = MonitorAffiliations.monitor_id
GROUP BY BetterMonitors.monitor_id;

-- The query shows the email and avg fees for  monitors who have a higher
-- average rating than all of the sites they monitor in
SELECT email, avg_fees
FROM Monitor, BetterMonitorsAvgFee
WHERE Monitor.id = BetterMonitorsAvgFee.monitor_id;