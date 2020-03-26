-- Could not implement monitors diving more than twice in a 24 hour period
-- as it will require a trigger
--
-- Could not implement capacity checks of divers for monitors or sites as it
-- would require creating a trigger that uses other tables to check that the
-- maximum is not violated. The data is stored in other tables to reduce
-- redundancy
--
-- Could not check diver age and certification as they would require a trigger
-- which accesses the Diver relation from the SubBooking relation.

CREATE TABLE CreditCardInfo(
 id INT PRIMARY KEY,
 diver_id INT REFERENCES Diver,
 card_number VARCHAR(19) NOT NULL CHECK (char_length(card_number) >= 13),
 expiration timestamp NOT NULL,
 security_code VARCHAR(4) NOT NULL
);




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
surname VARCHAR(50) NOT NULL,
-- The email of the monitor.
email varchar(30) NOT NULL
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
-- price for monitor site type combination, the fee here includes monitor and
-- site fees
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
-- price per diver at time of booking, can be different than current price in
-- MonitorAffiliations table
price NUMERIC NOT NULL CHECK(price >= 0),
-- date and start time of the dive for the booking
date timestamp NOT NULL,
-- same lead same date time different booking
UNIQUE (affiliation_id, date),
UNIQUE (lead_id, date)
);

-- Divers included in a booking and extras purchased
CREATE TABLE SubBooking (
-- the booking the diver is included in
booking_id INT REFERENCES Booking,
-- the diver associated with the booking
diver_id INT REFERENCES Diver,
-- extras
-- prices can be different than those in the DiveSiteExtrasFees table depending
-- on time of purchase
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

