SET SEARCH_PATH TO wetworldschema, public;

DROP VIEW IF EXISTS ALLFEES CASCADE;

-- The view includes for every booking the total fees paid for the booking
-- excluding extra fees 
CREATE VIEW ALLFEES AS
SELECT sum(Booking.price) AS total_fees, site_id
FROM SubBooking, MonitorAffiliations, Booking
WHERE Booking.affiliation_id = MonitorAffiliations.id
      AND SubBooking.booking_id = Booking.id
GROUP BY booking_id,site_id;

-- The query will get for every site its average, minimum and maximum fees paid
-- for any booking that takes place in it. If a site did not get any bookings
-- then it is not included in this query
SELECT site_id, avg(total_fees), min(total_fees), max(total_fees)
FROM ALLFEES
GROUP BY ALLFEES.site_id;
