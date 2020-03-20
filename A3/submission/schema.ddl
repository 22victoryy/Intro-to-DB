DROP SCHEMA IF EXISTS wetworldschema CASCADE;
CREATE SCHEMA wetworldschema;
SET search_path TO wetworldschema;
CREATE TYPE certification AS ENUM ('NAUI', 'CMAS', 'PADI');
 
-- A diver who dives.
CREATE TABLE Diver (
id INT PRIMARY KEY,
-- The first name of the diver.
firstname VARCHAR(50) NOT NULL,
-- The surname of the diver.
surname VARCHAR(50) NOT NULL,
-- The email of the diver.
email varchar(30) NOT NULL,
-- The date of birth of the diver
dob timestamp NOT NULL CHECK (dob <= current_timestamp),
-- certification that the diver has
certification certification
);
 
-- A site for diving
CREATE TABLE DiveSite (
id INT PRIMARY KEY,
-- name of the dive site
name VARCHAR(50) NOT NULL,
-- required fees per diver
req_fees NUMERIC NOT NULL CHECK (req_fees >= 0),
-- the capacity of the dive site during day hours
day_capacity INT NOT NULL CHECK (day_capacity >= 0),
-- the capacity of the dive site during night hours
night_capacity INT NOT NULL CHECK (night_capacity >= 0),
-- the capacity of the dive site for cave dives
-- value is zero if site does not provide it
cave_capacity INT NOT NULL CHECK (cave_capacity >= 0),
-- the capacity of the dive site for deeper than 30 dives
-- value is zero if site does not provide it
deeper30_capacity INT NOT NULL CHECK (deeper30_capacity >= 0),
-- whether the dive site provides open water diving
open BOOLEAN NOT NULL,
CHECK (day_capacity >= night_capacity AND day_capacity >= cave_capacity
       AND day_capacity >= deeper30_capacity)
);
 
-- Fees charged by dive sites for extra equipment
CREATE TABLE DiveSiteExtrasFees(
id INT PRIMARY KEY REFERENCES DiveSite,
-- fee for mask per diver
mask NUMERIC CHECK (mask >= 0),
-- fee for regulator per diver
regulator NUMERIC CHECK (regulator >= 0),
-- fee for fins per diver
fins NUMERIC CHECK (fins >= 0),
-- fee for wrist-mounted dive computer per diver
computer NUMERIC CHECK (computer >= 0)
);
 
-- A dive monitor
CREATE TABLE Monitor(
id INT PRIMARY KEY,
-- The first name of the monitor
firstname VARCHAR(50) NOT NULL,
-- The surname of the monitor
surname VARCHAR(50) NOT NULL
);
-- dive type
CREATE TYPE dive_type AS ENUM ('open water', 'cave', 'deeper than 30');
-- dive time
CREATE TYPE dive_time AS ENUM ('morning', 'afternoon', 'night');
 
-- The capacity of each monitor for each dive type
CREATE TABLE MonitorCapacity (
-- monitor id
monitor_id INT REFERENCES Monitor,
-- the dive type
dive_type dive_type NOT NULL,
-- the capacity the monitor is willing to accomodate
capacity INT NOT NULL CHECK (capacity >= 0),
PRIMARY KEY (monitor_id, dive_type)
);
 
-- The fee the monitor charges depending on their affliated site, dive time and
-- dive type
CREATE TABLE MonitorAffiliations (
id INT PRIMARY KEY,
-- monitor id
monitor_id INT REFERENCES Monitor,
-- the dive type
dive_type dive_type NOT NULL,
-- the affiliated site id
site_id INT REFERENCES DiveSite,
-- the dive time of the diving
dive_time dive_time NOT NULL,
-- price for monitor site type combination
price NUMERIC NOT NULL CHECK (price > 0),
UNIQUE (monitor_id, site_id, dive_time, dive_type)
);
 
-- A dive booking
CREATE TABLE Booking (
id INT PRIMARY KEY,
-- lead diver for the booking
lead_id INT REFERENCES Diver,
-- monitor affiliation for the booking
affiliation_id INT REFERENCES MonitorAffiliations,
-- price per diver at time of booking
price NUMERIC NOT NULL CHECK(price >= 0),
-- date of the dive for the booking,
date timestamp NOT NULL,
-- nitrogen level
-- same lead same date time different booking
UNIQUE (affiliation_id, date)
);

CREATE VIEW BookingInfo AS
SELECT Booking.id AS id, lead_id, date, monitor_id, dive_time, dive_type, site_id
FROM Booking JOIN MonitorAffiliations
     ON Booking.affiliation_id = MonitorAffiliations.id;
-- TODO: check if the monitor does the dive_type (i.e capacity > 0)
CREATE OR REPLACE FUNCTION nitrogen_trigger() RETURNS trigger AS $nitrogen_check$

DECLARE
    new_time dive_time;
    num_dives integer;
    mid integer;
BEGIN
    WITH con (vid) AS (VALUES (NEW.affiliation_id))
    SELECT dive_time, monitor_id INTO new_time, mid
    FROM MonitorAffiliations, con
    WHERE MonitorAffiliations.id = vid;

    IF new_time = 'morning' THEN
        NEW.date := date_trunc('day', NEW.date) + '9:30:00';
    ELSIF new_time = 'afternoon' THEN
        NEW.date := date_trunc('day', NEW.date) + '12:30:00';
    ELSIF new_time = 'night' THEN
        NEW.date := date_trunc('day', NEW.date) + '20:30:00';
    END IF;
    --- Check if the diver has dived more than three times
    WITH con (vdate) AS (VALUES (NEW.date))
    SELECT count(*) INTO num_dives
    FROM BookingInfo, con
    WHERE BookingInfo.monitor_id = mid AND
         (BookingInfo.date - vdate < '24:00:00' OR
          vdate - BookingInfo.date < '24:00:00');
    IF num_dives = 2 THEN
        RETURN NULL;
    END IF;
    RETURN NEW;
END;
$nitrogen_check$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION lead_trigger() RETURNS trigger AS $lead$
DECLARE
    -- Lead diver cannot have multiple bookings on the same date and time
    count integer;
    new_time dive_time;
BEGIN
WITH con (vid) AS (VALUES (NEW.affiliation_id))
    SELECT dive_time INTO new_time
    FROM MonitorAffiliations, con
    WHERE MonitorAffiliations.id = vid;

    WITH con (lid, vdate) AS (VALUES (NEW.lead_id, NEW.date))
    SELECT count(*) INTO count
    FROM BookingInfo, con
    WHERE BookingInfo.lead_id = lid AND
          date_trunc('day', BookingInfo.date)=date_trunc('day', vdate) AND
          BookingInfo.dive_time=new_time;
    IF count > 0 THEN
        RETURN NULL;
    END IF;
    RETURN NEW;
END;
$lead$ LANGUAGE plpgsql;

CREATE TRIGGER monitor_nitrogen
BEFORE UPDATE OR INSERT
ON Booking
FOR EACH ROW
EXECUTE PROCEDURE nitrogen_trigger();

CREATE TRIGGER lead_same_date_time
BEFORE UPDATE OR INSERT
ON Booking
FOR EACH ROW
EXECUTE PROCEDURE lead_trigger();

-- Divers included in a booking and extras purchased
CREATE TABLE SubBooking (
-- the booking the diver is included in
booking_id INT REFERENCES Booking,
-- the diver associated with the booking
diver_id INT REFERENCES Diver,
-- extras
-- fee paid for mask, zero if not purchased
mask NUMERIC NOT NULL CHECK (mask >= 0) DEFAULT 0,
-- fee paid for regulator, zero if not purchased
regulator NUMERIC NOT NULL CHECK (regulator >= 0) DEFAULT 0,
-- fee paid for fins, zero if not purchased
fins NUMERIC CHECK (fins >= 0) DEFAULT 0,
-- fee paid for wrist-mounted dive computer, zero if not purchased
computer NUMERIC CHECK (computer >= 0) DEFAULT 0,
PRIMARY KEY (booking_id, diver_id)
);
 
CREATE OR REPLACE FUNCTION capacity_trigger() RETURNS trigger AS $capacity_trigger$
DECLARE
    new_time dive_time;
    new_type dive_type;
    new_monitor_id integer;
    monitor_capacity integer;
    divesite_capacity_day integer;
    divesite_capacity_night integer;
    divesite_capacity_cave integer;
    divesite_capacity_deeper integer;
    new_site_id integer;
    sub_booking_count integer;
    site_count integer;
BEGIN
    WITH con (bid) AS (VALUES (NEW.booking_id))
    SELECT dive_time, dive_type, BookingInfo.monitor_id, BookingInfo.site_id
	       INTO new_time, new_type, new_monitor_id, new_site_id
    FROM BookingInfo, con
    WHERE BookingInfo.id = bid;
 
    WITH con (bid) AS (VALUES (NEW.booking_id))
    SELECT count(*) INTO sub_booking_count
    FROM SubBooking, con
    WHERE SubBooking.booking_id = bid;
 
    SELECT capacity INTO monitor_capacity
    FROM MonitorCapacity
    WHERE MonitorCapacity.monitor_id = new_monitor_id AND MonitorCapacity.dive_type=new_type;
 
    IF sub_booking_count >= monitor_capacity THEN
        RETURN NULL;
    END IF;
 
    SELECT day_capacity, night_capacity, cave_capacity, deeper30_capacity
	       INTO divesite_capacity_day, divesite_capacity_night,
	            divesite_capacity_cave, divesite_capacity_deeper
    FROM DiveSite 
    WHERE (DiveSite.id = new_site_id); 
 
    CREATE OR REPLACE VIEW SiteBookings AS
    SELECT dive_type, count(*) AS count
    FROM SubBooking JOIN BookingInfo ON
         SubBooking.booking_id = BookingInfo.id
    WHERE BookingInfo.site_id = new_site_id AND dive_time = new_time
    GROUP BY dive_type;
 
    IF new_time = 'night' THEN
        IF (SELECT sum(count) FROM SiteBookings) >= divesite_capacity_night THEN
            RETURN NULL;
        END IF;
    ELSE
        IF (SELECT sum(count) FROM SiteBookings) >= divesite_capacity_day THEN
            RETURN NULL;
        END IF;
    END IF;
    
    IF new_type = 'cave' THEN
        IF (SELECT count
            FROM SiteBookings
            WHERE dive_type = new_type) >= divesite_capacity_cave THEN
            RETURN NULL;
        END IF;
    ELSIF new_type = 'deeper than 30' THEN
        IF (SELECT count
            FROM SiteBookings
            WHERE dive_type = new_type) >= divesite_capacity_deeper THEN
            RETURN NULL;
        END IF;
    END IF;
    RETURN NEW;
END;
$capacity_trigger$ LANGUAGE plpgsql;
 
CREATE OR REPLACE FUNCTION diver_elig_trigger() RETURNS trigger AS $diver_elig_trigger$
DECLARE
    dob timestamp;
    booking_date timestamp;
    certification certification;
BEGIN
    WITH con (did) AS (VALUES (NEW.diver_id))
    SELECT dob, certification INTO dob, certification
    FROM Diver, con
    WHERE Diver.id=did;
 
    WITH con (bid) AS (VALUES (NEW.booking_id))
    SELECT date_trunc('day', BookingInfo.date) INTO booking_date
    FROM BookingInfo, con
    WHERE BookingInfo.id=bid;
 
    IF (booking_date - dob < INTERVAL '16 years')
       OR certification IS NULL THEN 
        RETURN NULL;
    END IF;
    RETURN NEW;
END;
$diver_elig_trigger$ LANGUAGE plpgsql;
 
CREATE TRIGGER capacity_trigger
BEFORE UPDATE OR INSERT
ON SubBooking
FOR EACH ROW
EXECUTE PROCEDURE capacity_trigger();
 
CREATE TRIGGER diver_elig_trigger
BEFORE UPDATE OR INSERT
ON SubBooking
FOR EACH ROW
EXECUTE PROCEDURE diver_elig_trigger();
 
-- Rating for monitors by lead divers that have booked with them
CREATE TABLE MonitorRating (
-- booking id to which the rating corresponds to
id INT PRIMARY KEY REFERENCES Booking,
-- rating
rating INT CHECK (0 <= rating and rating <= 5) NOT NULL
);
 
-- Ratings for sites by divers
CREATE TABLE SiteRating (
-- booking that the diver is rating
booking_id INT,
diver_id INT,
rating INT CHECK (0 <= rating and rating <= 5) NOT NULL,
PRIMARY KEY (booking_id, diver_id),
FOREIGN KEY (booking_id, diver_id) REFERENCES SubBooking
);
