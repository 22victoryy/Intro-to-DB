SET SEARCH_PATH TO wetworldschema, public;

CREATE VIEW ALLFEES AS
SELECT req_fees
FROM Divesite INNER JOIN DiveSiteExtrasFees ON(Divesite.id = DiveSiteExtrasFees.id);