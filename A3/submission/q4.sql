SET SEARCH_PATH TO wetworldschema, public;

DROP VIEW IF EXISTS ALLFEES CASCADE;

CREATE VIEW ALLFEES AS
SELECT price, site_id
FROM subbooking INNER JOIN MonitorAffiliations ON (MonitorAffiliations.monitor_id = subbooking.diver_id);

SELECT avg(price), min(price), max(price)
FROM ALLFEES
GROUP BY site_id





-- -- Divers included in a booking and extras purchased
-- CREATE TABLE SubBooking (
-- -- the booking the diver is included in
-- booking_id INT REFERENCES Booking,
-- -- the diver associated with the booking
-- diver_id INT REFERENCES Diver,
-- -- extras
-- -- fee paid for mask, zero if not purchased
-- mask NUMERIC NOT NULL CHECK (mask >= 0) DEFAULT 0,
-- -- fee paid for regulator, zero if not purchased
-- regulator NUMERIC NOT NULL CHECK (regulator >= 0) DEFAULT 0,
-- -- fee paid for fins, zero if not purchased
-- fins NUMERIC CHECK (fins >= 0) DEFAULT 0,
-- -- fee paid for wrist-mounted dive computer, zero if not purchased
-- computer NUMERIC CHECK (computer >= 0) DEFAULT 0,
-- PRIMARY KEY (booking_id, diver_id)
-- );


-- CREATE TABLE MonitorAffiliations (
-- id INT PRIMARY KEY,
-- -- monitor id
-- monitor_id INT REFERENCES Monitor,
-- -- the dive type
-- dive_type dive_type NOT NULL,
-- -- the affiliated site id
-- site_id INT REFERENCES DiveSite,
-- -- the dive time of the diving
-- dive_time dive_time NOT NULL,
-- -- price for monitor site type combination
-- price NUMERIC NOT NULL CHECK (price > 0),
-- UNIQUE (monitor_id, site_id, dive_time, dive_type)
-- );
 