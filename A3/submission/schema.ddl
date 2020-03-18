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
 
CREATE TABLE DiveSiteExtrasPrice(
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
 
CREATE TABLE Monitor(
 id INT PRIMARY KEY,
 -- The first name of the diver
 firstname VARCHAR(50) NOT NULL,
 -- The surname of the passenger
 surname VARCHAR(50) NOT NULL
);
 
-- dive type
CREATE TYPE dive_type AS ENUM ('open water', 'cave', 'deeper than 30');
-- dive time
CREATE TYPE dive_time AS ENUM ('morning', 'afternoon', 'night');
 
CREATE TABLE MonitorCapacity (
 -- monitor id
 monitor_id INT REFERENCES Monitor,
 -- the dive type
 dive_type dive_type NOT NULL,
 -- the capacity the monitor is willing to accomodate
 capacity INT NOT NULL CHECK (capacity >= 0),
 PRIMARY KEY (monitor_id, dive_type)
);
 
CREATE TABLE MonitorFee (
 -- monitor id
 monitor_id INT REFERENCES Monitor,
 -- the dive type
 dive_type dive_type NOT NULL,
 -- the site id
 site_id INT REFERENCES DiveSite,
 -- the dive time of the diving
 dive_time dive_time NOT NULL,
 -- price for monitor site type combination
 price NUMERIC NOT NULL CHECK (price > 0),
 PRIMARY KEY (monitor_id, site_id, dive_time, dive_type)
);
 
CREATE TABLE Booking (
 id INT PRIMARY KEY,
 -- lead diver for the booking
 lead_id INT REFERENCES Diver,
 -- monitor for the booking
 monitor_id INT REFERENCES Monitor,
 -- dive site for the booking
 site_id INT REFERENCES DiveSite,
 -- dive type of the booking
 dive_type dive_type NOT NULL,
 -- timestamp for the day of the booking,
 date timestamp NOT NULL CHECK (date > current_timestamp),
 -- time in which the dive takes place,
 dive_time dive_time NOT NULL,
 FOREIGN KEY (monitor_id, site_id, dive_time, dive_type) REFERENCES MonitorFee
 
 -- nitrogen level
 -- same lead same date time different booking
 );
 
-- CREATE TRIGGER monitor_nitrogen
	-- BEFORE UPDATE OR INSERT
	-- ON Booking
	-- FOR EACH ROW
	-- WHEN (NEW.monitor_id = OLD.monitor_id AND
            -- NEW.date - OLD.date < ‘48:00:00’)
	--EXECUTE PROCEDURE sth();
 
CREATE TABLE MonitorRating (
 -- booking id to which the rating corresponds to
 id INT PRIMARY KEY REFERENCES Booking,
 -- rating 
 rating INT CHECK (0 <= rating and rating <= 5) NOT NULL
);
 
CREATE TABLE SubBooking (
 -- dosomething
 booking_id INT REFERENCES Booking,
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
 
CREATE TABLE SiteRating (
 booking_id INT,
 diver_id INT,
 rating INT CHECK (0 <= rating and rating <= 5) NOT NULL,
 PRIMARY KEY (booking_id, diver_id),
 FOREIGN KEY (booking_id, diver_id) REFERENCES SubBooking
);
 
