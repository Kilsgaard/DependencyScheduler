CREATE FUNCTION [utl].[CamelCase]
(@Str nvarchar(max))
RETURNS nvarchar(max) AS
BEGIN
  DECLARE @Result nvarchar(max)
  SET @Str = LOWER(@Str) + ' '
  SET @Result = ''
  WHILE 1=1
  BEGIN
    IF PATINDEX('% %',@Str) = 0 BREAK
    SET @Result = @Result + UPPER(Left(@Str,1))+
    SubString  (@Str,2,CharIndex(' ',@Str)-1)
    SET @Str = SubString(@Str,
      CharIndex(' ',@Str)+1,Len(@Str))
  END
  SET @Result = Left(@Result,Len(@Result))
  RETURN @Result
END