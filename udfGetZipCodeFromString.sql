/*******************************************************************************
** File:	  udfGetZipCodeFromString.sql 
**
** Name:	  udfGetZipCodeFromString
**
** Target:  SQL Server 2012+
**
** Desc:	  This function looks recursively for the 1st correct US Zip code withing a string and
		  returns it in the varchar(8) fomat or 'n/a' if not found. Works for both formats 
		  'CA 90405' and 'CA90405'. The recursion ensures that if the Zip Code pattern is found 
		  but it is not a valid Zip (it could be just a string section coincidentaly formatted as 
		  Zip) it moves to another pattern match.

		  The number of recursions allowed per one string search can be set by the 2nd parameter to
		  prevent infinite looping in some strange cases. Max recursuon value is 32 - SQL default.
**
** Auth:	  Copyleft, Milan Polak (2017 - 2018)
** Ref:	  (https://www.copyleft.org/)
**
** Sample Usage: Select Zip Code from a string with maximum recursion set to 15
**    
**				SELECT dbo.udfGetZipCodeFromString(1, 15, 1, @addressString)
**
** Change History:
**
** Version	 Date		  Author	    Description 
** -------	 --------		  -------	    ------------------------------------
** 1.001		 2017-11-06      Mpo	    Initial Version
** 1.002		 2018-03-08      Mpo	    Added [a-zA-Z][a-zA-Z][0-9][0-9][0-9][0-9][0-9] pattern
**
*********************************************************************************/

ALTER FUNCTION udfGetZipCodeFromString(@rec INT, @maxRec INT, @offset INT, @addressString nVARCHAR(max))
RETURNS VARCHAR(8)  
WITH EXECUTE AS CALLER  
AS  
BEGIN

    DECLARE @zip AS VARCHAR(8)  = 'n/a';
    DECLARE @addressStringTr AS nVARCHAR(max) = REPLACE(SUBSTRING(@addressString, @offset, 40000), ' ', '');

    -- Filter on valid Zip nums & valid Zip aplha-codes.
    -- Mutual check for both formts 'CA 90405' and 'CA90405'
    IF ISNULL(TRY_CAST(SUBSTRING(@addressString, PATINDEX('%[0-9][0-9][0-9][0-9][0-9]%', @addressString),2) AS INT), 100) < 100 
	   AND SUBSTRING(@addressString, PATINDEX('%[a-zA-Z][a-zA-Z][0-9][0-9][0-9][0-9][0-9]%', @addressString),2) IN(
	   'AL','AK','AZ','AR','CA','CO','CT','DE','DC','FL','GA','HI','ID','IL','IN','IA','KS','KY','LA','ME',
	   'MD','MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ','NM','NY','NC','ND','OH','OK','OR','PA','RI',
	   'SC','SD','TN','TX','UT','VT','VA','WA','WV','WI','WY','AS','GU','MP','PR','UM','VI','AA','AP','AE')
    BEGIN
	  SELECT @zip = IIF(PATINDEX('%[a-zA-Z][a-zA-Z][0-9][0-9][0-9][0-9][0-9]%', @addressString) > 0, 
					   STUFF(SUBSTRING(@addressString, PATINDEX('%[a-zA-Z][a-zA-Z][0-9][0-9][0-9][0-9][0-9]%', 
					   @addressString), 7), 3, 0, ' '), 'n/a');
    END
    ELSE
    BEGIN
	   SET @offset = @offset + PATINDEX('%[0-9][0-9][0-9][0-9][0-9]%', @addressStringTr);
	    
	   IF @maxRec > @rec
	   BEGIN
		  SELECT @zip = dbo.udfGetZipCodeFromString(@rec + 1, @maxRec, @offset, @addressStringTr)
	   END

    END

	   RETURN(@zip); 
END;