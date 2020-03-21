SET SEARCH_PATH TO wetworldschema, public;

DROP VIEW IF EXISTS AvgSiteRating CASCADE;
DROP VIEW IF EXISTS AvgMonitorRating CASCADE;
DROP VIEW IF EXISTS BetterMonitors CASCADE;
DROP VIEW IF EXISTS BetterMonitorsAvgFee CASCADE;


CREATE VIEW AvgSiteRating AS
SELECT MonitorAffiliations.site_id AS site_id,
       avg(SiteRating.rating) AS avg_rating 
FROM SiteRating, Booking, MonitorAffiliations
WHERE SiteRating.booking_id = Booking.id AND
      Booking.affiliation_id = MonitorAffiliations.id
GROUP BY MonitorAffiliations.site_id;

CREATE VIEW AvgMonitorRating AS
SELECT MonitorAffiliations.monitor_id AS monitor_id,
       avg(MonitorRating.rating) AS avg_rating 
FROM MonitorRating, Booking, MonitorAffiliations
WHERE MonitorRating.id = Booking.id AND
      Booking.affiliation_id = MonitorAffiliations.id
GROUP BY MonitorAffiliations.monitor_id;

CREATE VIEW BetterMonitors AS
SELECT monitor_id
FROM AvgMonitorRating
WHERE avg_rating > ALL (SELECT avg_rating
                        FROM AvgSiteRating, MonitorAffiliations MA
                        WHERE AvgSiteRating.site_id = MA.site_id
                        AND MA.monitor_id = AvgMonitorRating.monitor_id);

CREATE VIEW BetterMonitorsAvgFee AS
SELECT BetterMonitors.monitor_id, avg(MonitorAffiliations.price) AS avg_fees
FROM BetterMonitors, MonitorAffiliations
WHERE BetterMonitors.monitor_id = MonitorAffiliations.monitor_id
GROUP BY BetterMonitors.monitor_id;

SELECT email, avg_fees
FROM Monitor, BetterMonitorsAvgFee
WHERE Monitor.id = BetterMonitorsAvgFee.monitor_id;