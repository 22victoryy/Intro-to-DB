SET SEARCH_PATH TO wetworldschema, public;

DROP VIEW IF EXISTS ALLFEES CASCADE;

CREATE VIEW ALLFEES AS
SELECT sum(Booking.price), site_id
FROM SubBooking, MonitorAffiliations, Booking
WHERE Booking.affiliation_id = MonitorAffiliations.id AND SubBooking.booking_id = Booking.id
GROUP BY booking_id,site_id;

SELECT site_id, avg(sum), min(sum), max(sum)
FROM ALLFEES
GROUP BY ALLFEES.site_id;
