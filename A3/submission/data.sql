INSERT INTO DiveSite VALUES
(1, 'Bloody Bay Marine Park', 10,  5, 5, 5, 5,  true),
(2,     'Widow Maker''s Cave', 20, 10, 5, 5, 5,  true),
(3,            'Crystal Bay', 15, 10, 5, 5, 5,  true),
(4,            'Batu Bolong', 15, 10, 3, 3, 3,  true),
(5,            'The Bay Bay', 20,  5, 3, 3, 3, false);
 
INSERT INTO DiveSiteExtrasFees VALUES
(1,    5, NULL,    10, NULL),
(2,    3, NULL,     5, NULL),
(3, NULL, NULL,     5,   20),
(4,   10, NULL,  NULL,   30);
 
INSERT INTO Monitor VALUES
(1, 'Maria', 'Mahboob'),
(2, 'John', 'Heap'),
(3, 'Ben', 'Dover');
 
INSERT INTO MonitorCapacity VALUES
(1, 'open water',     10),
(1, 'cave',           5 ),
(1, 'deeper than 30', 5 ),
 
(2, 'open water',     15),
(2, 'cave',           10),
(2, 'deeper than 30',  0),
 
(3, 'open water',    15),
(3, 'cave',           5),
(3, 'deeper than 30', 5);
 
INSERT INTO MonitorAffiliations VALUES
(1, 1,           'cave', 1,     'night', 25),
(2, 1,     'open water', 2,   'morning', 10),
(3, 1,           'cave', 2,   'morning', 20),
(4, 1,     'open water', 3, 'afternoon', 25),
(5, 1,           'cave', 4,   'morning', 30),
(6, 2,           'cave', 1,   'morning', 15),
(7, 3,           'cave', 2,   'morning', 20);
 
INSERT INTO Diver VALUES
(1, 'Michael', 'Scott',   'michael@dm.org', '1962-08-16', 'PADI'),
(2, 'Dwight',  'Schrute', 'dwight@dm.org',  '1966-01-20', 'NAUI'),
(3, 'Jim',     'Halpert', 'jim@dm.org',     '1979-11-20', 'CMAS'),
(4, 'Pam',      'Beesly', 'pam@dm.org',     '1974-03-07', 'PADI'),
(5, 'Andy',    'Bernard', 'andy@dm.org',    '1974-01-24', 'PADI'),
(6, 'Phyllis',   'Vance', 'phyllis@dm.org', '1951-10-07', 'PADI'),
(7, 'Oscar',  'Martinez', 'oscar@dm.org',   '1958-11-18', 'PADI');
 
INSERT INTO Booking VALUES
(1, 1, 2, 10, '2019-07-20'),
(2, 1, 3, 20, '2019-07-21'),
(3, 1, 7, 20, '2019-07-22'),
(4, 1, 1, 25, '2019-07-22'),
(5, 2, 4, 25, '2019-07-22'),
(6, 2, 3, 20, '2019-07-23'),
(7, 2, 3, 20, '2019-07-24');
 
INSERT INTO SubBooking VALUES
(1, 1, 0, 0, 0, 0),
(1, 2, 0, 0, 0, 0),
(1, 3, 0, 0, 0, 0),
(1, 4, 0, 0, 0, 0),
(1, 5, 0, 0, 0, 0),
(2, 1, 0, 0, 0, 0),
(2, 2, 0, 0, 0, 0),
(2, 3, 0, 0, 0, 0),
(3, 1, 0, 0, 0, 0),
(3, 3, 0, 0, 0, 0),
(4, 1, 0, 0, 0, 0),
(5, 5, 0, 0, 0, 0),
(5, 1, 0, 0, 0, 0),
(5, 2, 0, 0, 0, 0),
(5, 3, 0, 0, 0, 0),
(5, 4, 0, 0, 0, 0),
(5, 6, 0, 0, 0, 0),
(5, 7, 0, 0, 0, 0),
(6, 5, 0, 0, 0, 0),
(7, 5, 0, 0, 0, 0);
