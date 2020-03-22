SET SEARCH_PATH TO wetworldschema, public;

CREATE VIEW ALLFEES AS
SELECT req_fees, mask, regulator, computer
FROM Divesite INNER JOIN DiveSiteExtrasFees ON(Divesite.id = DiveSiteExtrasFees.id);