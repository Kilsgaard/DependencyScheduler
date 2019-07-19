



-- =============================================
-- Author:		Graves Kilsgaard
-- Create date: 2015-03-05
-- Description:	Stored Procedure til at enable og disable Columnstorred Indexes på en database
--
-- Changes: 
-- Author:		Henrik Munch
-- Create date: 2015-03-07
-- Description:	Tilføjet mulighed for at include/exclude tabeller
-- =============================================
CREATE	PROCEDURE [flw].[HandlerForColumnStoreIndex]
	 --Add the parameters for the stored procedure here
	 @parmJobID			uniqueidentifier	=	NULL
	,@parmDBServer		VARCHAR(128)		=	NULL
	,@parmDBName		VARCHAR(128)		=	NULL 
	,@parmIdxAction		VARCHAR(7)			=	NULL -- DISABLE / REBUILD / DELETE / CREATE
	,@parmIncludeTables	VARCHAR(MAX)		=	NULL -- On these tables only
	,@parmExcludeTables	VARCHAR(MAX)		=	NULL -- On all tables except these 
	,@parmDelimiter		CHAR(1)				=	','  -- Delimiter character for include/exclude tables
	,@parmDebug			TINYINT				=	0	 -- 0 = No, 1 = Yes

AS
BEGIN
	SET NOCOUNT ON;

	-- ----- Test Variables -----
	--DECLARE @parmJobID					AS	uniqueidentifier	=	'5858D058-BE71-4211-BDB9-3BE32C8EAC79'
	--DECLARE @parmDBServer				AS	VARCHAR(128)		=	'BI-DPA-UDV\DPA'
	--DECLARE @parmDBName					AS	VARCHAR(128)		=	'DPA_Tvang'
	--DECLARE @parmIdxAction				AS	VARCHAR(7)			=	'CREATE' -- DISABLE / REBUILD / DELETE / CREATE
	--DECLARE @parmIncludeTables			AS	VARCHAR(max)		=	NULL --'[fct].[ForanstaltningerPrDato]' --NULL -- On these tables only, delimiter = ,
	--DECLARE @parmExcludeTables			AS	VARCHAR(max)		=	NULL -- On all tables except these, delimiter = , 
	--DECLARE @parmDebug					AS	TINYINT				=	1	 -- 0 = No, 1 = Yes
	--DECLARE @parmDelimiter				AS	CHAR(1)				=	','  -- Delimiter character for include/exclude tables
	-- -----
	DECLARE @CurrentBatchNumber			AS	VARCHAR(10)			=	CONVERT(VARCHAR(MAX), [flw].[CurrentBatchID](@parmJobID))
	DECLARE @TableForColumnStoreIndex	AS  VARCHAR(128)		=	'[flw].[TableForColumnStoreIndexTable]'
	DECLARE @LineBreak					AS  varchar(2)			=	CHAR(13) + CHAR(10)
	DECLARE @DBSrcServer				AS  VARCHAR(128)		=	 REPLACE(@parmDBServer,'DPA','DSA')
	-- -----
	DECLARE @SQL						AS  VARCHAR(MAX)		=	''

	-- Session Trace flag som giver detaljeret ouput om deadlocks in sql server error log
	DBCC TRACEON (1204)
	DBCC TRACEON (1222)

	-- -----
	if(object_id('tempdb..#IncludeTables')<>0)
		DROP TABLE #IncludeTables

	if(object_id('tempdb..#ExcludeTables')<>0)
		DROP TABLE #ExcludeTables

	SELECT QUOTENAME(PARSENAME([value],2)) + '.' + QUOTENAME(PARSENAME([value],1)) AS TableName
	INTO #IncludeTables
	FROM STRING_SPLIT(@parmIncludeTables,@parmDelimiter)

	IF(@parmDebug>0) SELECT 'Include', TableName FROM #IncludeTables

	SELECT QUOTENAME(PARSENAME([value],2)) + '.' + QUOTENAME(PARSENAME([value],1)) AS TableName
	INTO #ExcludeTables
	FROM STRING_SPLIT(@parmExcludeTables,@parmDelimiter)

	IF(@parmDebug>0) SELECT 'Exclude', TableName FROM #ExcludeTables

	IF (@parmIdxAction <> 'CREATE')
	BEGIN
	 -- ----- BUILD SQL STRING
	 SET @SQL	=	'USE [DataFlowManagement]'																																		+ @LineBreak
				+	'DECLARE @IDXName					AS VARCHAR(128)		=	'''''																		+ @LineBreak
				+	'DECLARE @TBLName					AS VARCHAR(128)		=	'''''																		+ @LineBreak
				+	'DECLARE @SCHName					AS VARCHAR(128)		=	'''''																		+ @LineBreak
				+   'DECLARE @DBServer					AS VARCHAR(128)		=   ''' + @parmDBServer + ''''													+ @LineBreak
				+	'DECLARE @DBName					AS VARCHAR(128)		=	''' + @parmDBName + ''''													+ @LineBreak
				+	'DECLARE @Action					AS VARCHAR(7)		=	''' + @parmIdxAction + ''''													+ @LineBreak
				+   'DECLARE @TableColumnStoreIndex		AS VARCHAR(255)		=	''' + QUOTENAME(@DBSrcServer) + '.[DataFlowManagement].' + @TableForColumnStoreIndex + '''' 		+ @LineBreak
				+   'DECLARE @JobID						AS uniqueidentifier =   '''	+ CONVERT(VARCHAR(MAX),@ParmJobID)	+ ''''								+ @LineBreak
				+   'DECLARE @CurrentBatchNumber		AS varchar(10)	    =   ''' + @CurrentBatchNumber + ''''											+ @LineBreak   
				+	'DECLARE @LineBreak					AS varchar(2)		=	''' + @LineBreak + ''''  													+ @LineBreak   
				+	'DECLARE @SQL2						AS VARCHAR(MAX)'																					+ @LineBreak   
				+	'IF OBJECT_ID(''tempdb..#TmpIndex'') IS NOT NULL '																						+ @LineBreak
				+	'	DROP TABLE #TmpIndex'																												+ @LineBreak
				+	'CREATE TABLE #TmpIndex'																												+ @LineBreak
				+	'( '																																	+ @LineBreak
				+	'	 [SysIDX_Name]			[varchar](128)	NOT NULL'																					+ @LineBreak
				+	'	,[SysTBL_Name]			[varchar](128)	NOT NULL'																					+ @LineBreak
				+	'	,[SysSCH_Name]			[varchar](128)	NOT NULL'																					+ @LineBreak
				+	')'																																		+ @LineBreak
				+	''																															+ @LineBreak
				+	'				INSERT INTO #TmpIndex'																						+ @LineBreak
				+	'					('																										+ @LineBreak
				+	'						 [SysIDX_Name]'																						+ @LineBreak
				+	'						,[SysTBL_Name]'																						+ @LineBreak
				+	'						,[SysSCH_Name]'																						+ @LineBreak
				+	'					)'																										+ @LineBreak
				+	'				SELECT	 SYSIDX.[name]'																						+ @LineBreak
				+	'						,SYSTBL.[name]'																						+ @LineBreak
				+	'						,SYSSCH.[name]'																						+ @LineBreak
				+	'				  FROM	' + QUOTENAME(@parmDBServer) + '.' + QUOTENAME(@parmDBName) + '.[sys].[indexes]		AS	SYSIDX WITH (NOLOCK)'		+ @LineBreak
				+	'			INNER JOIN  ' + QUOTENAME(@parmDBServer) + '.' + QUOTENAME(@parmDBName) + '.[sys].[tables]		AS	SYSTBL WITH (NOLOCK)'		+ @LineBreak
				+	'					ON	SYSIDX.[object_id]			=	SYSTBL.[object_id]'													+ @LineBreak
				+	'			INNER JOIN  ' + QUOTENAME(@parmDBServer) + '.' + QUOTENAME(@parmDBName) + '.[sys].[schemas]		AS	SYSSCH WITH (NOLOCK)'		+ @LineBreak
				+	'					ON	SYSSCH.[schema_id]			=	SYSTBL.[schema_id]'													+ @LineBreak
				+	'				 WHERE	SYSIDX.type					=	6	-- Nonclustered columnstore index'								+ @LineBreak

				IF((SELECT COUNT(*) FROM [dbo].[#IncludeTables])>0) 
					SET @SQL = @SQL 	
				+	'				 AND	QUOTENAME(SYSSCH.[name]) + ''.'' + QUOTENAME(SYSTBL.[name]) IN'										+ @LineBreak
				+	'						(SELECT TableName FROM #IncludeTables)'																+ @LineBreak

				IF((SELECT COUNT(*) FROM [dbo].[#ExcludeTables])>0) 
					SET @SQL = @SQL 	
				+	'				 AND	QUOTENAME(SYSSCH.[name]) + ''.'' + QUOTENAME(SYSTBL.[name]) NOT IN'									+ @LineBreak
				+	'						(SELECT TableName FROM #ExcludeTables)'																+ @LineBreak

				SET @SQL = @SQL 	
				+	'			  --ORDER BY name'																								+ @LineBreak
				+	'-- ----- Lav Cursor til de indexes vi skal arbejde på -----'																+ @LineBreak
				+	'DECLARE db_csr CURSOR LOCAL FAST_FORWARD FOR'																				+ @LineBreak
				+	'	SELECT	 [SysIDX_Name]'																									+ @LineBreak
				+	'			,[SysTBL_Name]'																									+ @LineBreak
				+	'			,[SysSCH_Name]'																									+ @LineBreak
				+	'	 FROM	#TmpIndex'																										+ @LineBreak
				+	'-- ----- Loop Databaser og opret det som er krævet -----'																	+ @LineBreak
				+	' OPEN db_csr'																												+ @LineBreak
				+	'FETCH NEXT FROM db_csr'																									+ @LineBreak
				+	'		    INTO @IDXName, @TBLName, @SCHName'																				+ @LineBreak
				+	'-- -----'																													+ @LineBreak
				+	'WHILE @@FETCH_STATUS = 0'																									+ @LineBreak
				+	'BEGIN'																														+ @LineBreak
				+   '   SET @SQL2 = '''''																										+ @LineBreak
				-- ----- Diasble
				+	'	IF (@Action = ''DISABLE'')'																								+ @LineBreak
				+   '	BEGIN'																													+ @LineBreak
				+   '       SET @SQL2 =	QUOTENAME(@DBServer) + ''.'' +  QUOTENAME(@DBName)  + ''.dbo.sp_executesql N''''USE '' +  QUOTENAME(@DBName)'  		+ @LineBreak
				+   '					+ '' ALTER INDEX '' +  QUOTENAME(@IDXName) + '' ON '' + QUOTENAME(@SCHName) + ''.'' + QUOTENAME(@TBLName) + '' DISABLE'''''''		+ @LineBreak
				IF(@parmDebug>0) 
					SET @SQL = @SQL 	
				+	'		--PRINT (@SQL2)'																										+ @LineBreak
				
				SET @SQL = @SQL 	
				+	'		EXEC (@SQL2)'																										+ @LineBreak
				+	'	END'																													+ @LineBreak
				-- ----- REBUILD
				+	'	ELSE IF (@Action = ''REBUILD'')'																						+ @LineBreak
				+   '	BEGIN'																													+ @LineBreak
				+   '       SET @SQL2 =	QUOTENAME(@DBServer) + ''.'' +  QUOTENAME(@DBName)  + ''.dbo.sp_executesql N''''USE '' +  QUOTENAME(@DBName)'  		+ @LineBreak
				+   '					+ '' ALTER INDEX '' +  QUOTENAME(@IDXName) + '' ON '' + QUOTENAME(@SCHName) + ''.'' + QUOTENAME(@TBLName) + '' REBUILD'''''''		+ @LineBreak
				IF(@parmDebug>0) 
					SET @SQL = @SQL 	
				+	'		--PRINT (@SQL2)'																										+ @LineBreak

				SET @SQL = @SQL 	
				+	'		EXEC (@SQL2)'																										+ @LineBreak
				+	'	END'																													+ @LineBreak
				-- ----- DELETE 
				+	'	ELSE IF (@Action = ''DELETE'')'																							+ @LineBreak
				+   '	BEGIN'																													+ @LineBreak
				+	'		-- ----- GEM gammelt index'																							+ @LineBreak
				+	'		SET @SQL2 = QUOTENAME(@DBServer) + ''.'' +  QUOTENAME(@DBName)  + ''.dbo.sp_executesql N''''USE '' +  QUOTENAME(@DBName)	+ @LineBreak
				+	'' IF (EXISTS (SELECT * FROM '' + @TableColumnStoreIndex			+ @LineBreak
				+	''     WHERE [CurrentBatchID] = '' + @CurrentBatchNumber														+ @LineBreak
				+	''  	 AND JOBID			  = '''''''''' + CONVERT(VARCHAR(MAX), @JobID)	+ ''''''''''''					+ @LineBreak
				+	''		 AND [DBName]		  = '''''''''' + @DBName + ''''''''''''												+ @LineBreak
				+	''		 AND [SchemaName]	  = '''''''''' + @SCHName + ''''''''''''																+ @LineBreak
				+	''		 AND [TableName]		= '''''''''' + @TBLName + ''''''''''))''							+ @LineBreak
				+	'' BEGIN ''																											+ @LineBreak
				+	''	DELETE FROM '' + @TableColumnStoreIndex			+ @LineBreak
				+	''	 WHERE [CurrentBatchID] = '' + @CurrentBatchNumber																+ @LineBreak
				+	''	   AND [JOBID]			= '''''''''' + CONVERT(VARCHAR(MAX), @JobID)	+ ''''''''''''							+ @LineBreak
				+	''	   AND [DBName]			= '''''''''' + @DBName							+ ''''''''''''							+ @LineBreak
				+	''	   AND [SchemaName]		= '''''''''' + @SCHName + ''''''''''''	
				+	''	   AND [TableName]		= '''''''''' + @TBLName + ''''''''''''
				+	'' END ''		
				+	'' INSERT INTO '' + @TableColumnStoreIndex			+ @LineBreak
				+	''					( ''								+ @LineBreak																										
				+	''					  [CurrentBatchID]	''				+ @LineBreak																						
				+	''					 ,[JobID]'' 						+ @LineBreak																										
				+	''					 ,[DBName]''						+ @LineBreak																									
				+	''					 ,[SchemaName]''					+ @LineBreak																								
				+	''					 ,[TableName]''						+ @LineBreak																								
				+	''					 ,[IndexName]''						+ @LineBreak																								
				+	''					 ,[FileGroupName]''						+ @LineBreak																								
				+	''					 ,[CSIFileGroupName]''						+ @LineBreak																								
				+	''					 ,[IndexColumns]''					+ @LineBreak
				+	''					)''									+ @LineBreak
				+	''      SELECT '' + @CurrentBatchNumber																						+ @LineBreak 
				+	''			  ,'''''''''' + CONVERT(VARCHAR(MAX), @JobID)	+ ''''''''''''											        + @LineBreak
				+	''			  ,'''''''''' + @DBName + ''''''''''''																		    + @LineBreak
				+	''			  ,SysSchema.name''																								+ @LineBreak
				+	''			  ,SysTbl.name''																								+ @LineBreak
				+	''			  ,SysIdx.name''																								+ @LineBreak
				+	''			  ,SysFgs.name''																								+ @LineBreak
				+	''			  ,SysFgsCSI.name''																								+ @LineBreak
				+	''			  ,(SELECT SUBSTRING(''																							+ @LineBreak
				+	''				(SELECT '''''''','''''''' + QUOTENAME(SysClm.name)''														+ @LineBreak
				+	''				  FROM 	sys.index_columns						AS	SysIdxClm WITH (NOLOCK)''								+ @LineBreak
				+	''			INNER JOIN	sys.columns								AS	SysClm  WITH (NOLOCK)''									+ @LineBreak
				+	''					ON	SysIdxClm.object_id						=	SysClm.object_id''										+ @LineBreak 			
				+	''				   AND  SysIdxClm.object_id						=	SysIdx.object_id''+ @LineBreak
				+	''				   AND	SysIdxClm.index_id						=	SysIdx.index_id''+ @LineBreak
				+	''				   AND  SysIdxClm.column_id						=	SysClm.column_id''+ @LineBreak
				+	''			  ORDER BY	SysIdxClm.index_column_id''																			+ @LineBreak 
				+	''				   FOR XML PATH(''''''''''''''''),TYPE).value(''''''''.'''''''',''''''''varcHAR(MAX)''''''''),2,9999999)) AS IndexColumns''+ @LineBreak	
				+	''	   FROM	sys.schemas											AS	SysSchema  WITH (NOLOCK)''+ @LineBreak
				+	'' INNER JOIN  sys.tables											AS	SysTbl  WITH (NOLOCK)''+ @LineBreak
				+	'' 		 ON	SysTbl.schema_id									=	SysSchema.schema_id''+ @LineBreak
				+	'' INNER JOIN	sys.indexes											AS	SysIdx  WITH (NOLOCK)''										
				+	''     ON	SysIdx.object_id									=	SysTbl.object_id''
				+	'' INNER JOIN	sys.filegroups										AS	SysFgs  WITH (NOLOCK)''										
				+	''     ON	SysFgs.data_space_id									=	SysIdx.data_space_id''
				+	'' LEFT JOIN	sys.filegroups										AS	SysFgsCSI  WITH (NOLOCK)''										
				+	''     ON	SysFgsCSI.name									=	''''''''Standard'''''''' ''
				+	''  WHERE	SysIdx.is_primary_key								=	0''
				+	''	  AND	SysIdx.is_unique									=	0''
				+	''	  AND	SysIdx.is_unique_constraint							=	0''
				+	''	  AND	SysTbl.is_ms_shipped								=	0''
				+	''	  AND	SysTbl.name											=	'''''''''' + @TBLName + ''''''''''''
				+	''	  AND	SysSchema.name										=	'''''''''' + @SCHName + ''''''''''''
				+	''	  AND	SysIdx.name											=	'''''''''' + @IDXName + '''''''''';''+ @LineBreak 
				+	''DROP INDEX '' + QUOTENAME(@IDXName) + '' ON ''  + QUOTENAME(@SCHName) + ''.'' + QUOTENAME(@TBLName) 
				+   '''''''''																		
				+	'	EXEC (@SQL2)'																										+ @LineBreak
				+	'	--PRINT (@SQL2)'																										+ @LineBreak
				+	'	END'																													+ @LineBreak				
				+	'	-- ----- Next from Cursor -----'																						+ @LineBreak
				+	'	FETCH NEXT FROM db_csr'																									+ @LineBreak
				+	'		 INTO @IDXName, @TBLName, @SCHName'																					+ @LineBreak
				+	'END'																														+ @LineBreak
				+	'-- ----- Deallocat -----'																									+ @LineBreak
				+	'CLOSE db_csr'																												+ @LineBreak
				+	'DEALLOCATE db_csr'																											+ @LineBreak
				+	'IF OBJECT_ID(''tempdb..#TmpIndex'') IS NOT NULL '																			+ @LineBreak
				+	'	DROP TABLE #TmpIndex'																									+ @LineBreak
				+	'-- ----- END -----'																										+ @LineBreak
	END
	ELSE IF (@parmIdxAction = 'CREATE')
	BEGIN
	 SET @SQL	=	'USE [DataFlowManagement]'																												+ @LineBreak
				+	'DECLARE @BatchID					AS VARCHAR(128)		=	'''''																		+ @LineBreak
				+	'DECLARE @IDXColumns				AS VARCHAR(MAX)		=	'''''																		+ @LineBreak
				+	'DECLARE @IDXName					AS VARCHAR(128)		=	'''''																		+ @LineBreak
				+	'DECLARE @FGName					AS VARCHAR(128)		=	'''''																		+ @LineBreak
				+	'DECLARE @CSIFGName					AS VARCHAR(128)		=	'''''																		+ @LineBreak
				+	'DECLARE @TBLName					AS VARCHAR(128)		=	'''''																		+ @LineBreak
				+	'DECLARE @SCHName					AS VARCHAR(128)		=	'''''																		+ @LineBreak
				+	'DECLARE @CursorJobID				AS VARCHAR(128)		=	'''''																		+ @LineBreak
				+   'DECLARE @DBServer					AS VARCHAR(128)		=   ''' + @parmDBServer + ''''													+ @LineBreak
				+	'DECLARE @DBName					AS VARCHAR(128)		=	''' + @parmDBName + ''''													+ @LineBreak
				+	'DECLARE @Action					AS VARCHAR(7)		=	''' + @parmIdxAction + ''''													+ @LineBreak
				+   'DECLARE @TableColumnStoreIndex		AS VARCHAR(255)		=	''' + QUOTENAME(@DBSrcServer) + '.[DataFlowManagement].' + @TableForColumnStoreIndex + '''' 		+ @LineBreak
				+   'DECLARE @JobID						AS uniqueidentifier =   '''	+ CONVERT(VARCHAR(MAX),@ParmJobID)	+ ''''								+ @LineBreak
				+   'DECLARE @CurrentBatchNumber		AS varchar(10)	    =   ''' + @CurrentBatchNumber + ''''											+ @LineBreak   
				+	'DECLARE @LineBreak					AS varchar(2)		=	''' + @LineBreak + ''''  													+ @LineBreak   
				+	'DECLARE @SQL2						AS VARCHAR(MAX)'																					+ @LineBreak   
				+	'IF OBJECT_ID(''tempdb..#TmpClmTbl'') IS NOT NULL '																						+ @LineBreak
				+	'	DROP TABLE #TmpClmTbl'																												+ @LineBreak
				+	'CREATE TABLE #TmpClmTbl'																												+ @LineBreak
				+	'( '																														+ @LineBreak	
				+	'	 [CurrentBatchID]	[int] NOT NULL'																						+ @LineBreak
				+	'	,[JobID]			[uniqueidentifier] NOT NULL'																		+ @LineBreak
				+	'	,[DBName]			[varchar](128) NOT NULL'																			+ @LineBreak
				+	'	,[SchemaName]		[varchar](5) NOT NULL'																				+ @LineBreak
				+	'	,[TableName]		[varchar](128) NOT NULL'																			+ @LineBreak
				+	'	,[IndexName]		[varchar](128) NOT NULL'																			+ @LineBreak
				+	'	,[FileGroupName]		[varchar](128) NULL'																			+ @LineBreak
				+	'	,[CSIFileGroupName]		[varchar](128) NULL'																			+ @LineBreak
				+	'	,[IndexColumns]		[varchar](max) NOT NULL'																			+ @LineBreak
				+	')'																															+ @LineBreak
				+	''																															+ @LineBreak
				+	'				INSERT INTO #TmpClmTbl'																						+ @LineBreak
				+	'					('																										+ @LineBreak
				+	'						 [CurrentBatchID]'																					+ @LineBreak
				+	'						,[JobID]'																							+ @LineBreak
				+	'						,[DBName]'																							+ @LineBreak
				+	'						,[SchemaName]'																						+ @LineBreak
				+	'						,[TableName]'																						+ @LineBreak
				+	'						,[IndexName]'																						+ @LineBreak
				+	'						,[FileGroupName]'																						+ @LineBreak
				+	'						,[CSIFileGroupName]'																						+ @LineBreak
				+	'						,[IndexColumns]'																					+ @LineBreak
				+	'					)'																										+ @LineBreak
				+	''																															+ @LineBreak
				+	'				SELECT	 TCSI.[CurrentBatchID]'																				+ @LineBreak
				+	'						,TCSI.[JobID]'																						+ @LineBreak
				+	'						,TCSI.[DBName]'																						+ @LineBreak
				+	'						,TCSI.[SchemaName]'																					+ @LineBreak
				+	'						,TCSI.[TableName]'																					+ @LineBreak
				+	'						,TCSI.[IndexName]'																					+ @LineBreak
				+	'						,TCSI.[FileGroupName]'																					+ @LineBreak
				+	'						,TCSI.[CSIFileGroupName]'																					+ @LineBreak
				+	'						,TCSI.[IndexColumns]'																				+ @LineBreak
				+	'				  FROM  [DataFlowManagement].' + @TableForColumnStoreIndex + ' AS TCSI '	+ @LineBreak
				+	'				 WHERE	TCSI.[CurrentBatchID]				= ''' + @CurrentBatchNumber + '''' + @LineBreak
				+	'				   AND  TCSI.[JobID]						= ''' + CONVERT(VARCHAR(MAX),@parmJobID) + '''' + @LineBreak
				+   '				   AND  TCSI.[DBName]						= ''' + @parmDBName + '''' + @LineBreak
				
				IF((SELECT COUNT(*) FROM [dbo].[#IncludeTables])>0) 
					SET @SQL = @SQL 	
				+	'				 AND	QUOTENAME(TCSI.[SchemaName]) + ''.'' + QUOTENAME(TCSI.[TableName]) IN'								+ @LineBreak
				+	'						(SELECT TableName FROM #IncludeTables)'																+ @LineBreak

				IF((SELECT COUNT(*) FROM [dbo].[#ExcludeTables])>0) 
					SET @SQL = @SQL 	
				+	'				 AND	QUOTENAME(TCSI.[SchemaName]) + ''.'' + QUOTENAME(TCSI.[TableName]) NOT IN'								+ @LineBreak
				+	'						(SELECT TableName FROM #ExcludeTables)'																+ @LineBreak

				SET @SQL = @SQL 	
				+	'			  --ORDER BY name'																								+ @LineBreak
				+	'-- ----- Lav Cursor til de indexes vi skal arbejde på -----'																+ @LineBreak
				+	'DECLARE db_csr CURSOR LOCAL FAST_FORWARD FOR'																				+ @LineBreak
				+	'	SELECT	 [CurrentBatchID]'																								+ @LineBreak
				+	'			,[JobID]'																										+ @LineBreak
				+	'			,[DBName]'																										+ @LineBreak
				+	'			,[SchemaName]'																									+ @LineBreak
				+	'			,[TableName]'																									+ @LineBreak
				+	'			,[IndexName]'																									+ @LineBreak
				+	'			,[FileGroupName]'																									+ @LineBreak
				+	'			,[CSIFileGroupName]'																									+ @LineBreak
				+	'			,[IndexColumns]'																								+ @LineBreak
				+	'	 FROM	#TmpClmTbl'																										+ @LineBreak
				+	'-- ----- Loop Databaser og opret det som er krævet -----'																	+ @LineBreak
				+	' OPEN db_csr'																												+ @LineBreak
				+	'FETCH NEXT FROM db_csr'																									+ @LineBreak
				+	'		    INTO @BatchID, @CursorJobID, @DBName, @SCHName, @TBLName, @IDXName, @FGName, @CSIFGName, @IDXColumns'								+ @LineBreak
				+	'-- -----'																													+ @LineBreak
				+	'WHILE @@FETCH_STATUS = 0'																									+ @LineBreak
				+	'BEGIN'																														+ @LineBreak
				+	'		SET @SQL2 = QUOTENAME(@DBServer) + ''.'' +  QUOTENAME(@DBName)  + ''.dbo.sp_executesql N''''USE '' +  QUOTENAME(@DBName)	+ @LineBreak
				+	''IF (NOT EXISTS (SELECT  SYSIDX.[name]'' + @LineBreak
			    +	''				    FROM  [sys].[indexes]			AS	SYSIDX  WITH (NOLOCK)'' + @LineBreak
  				+	''			  INNER JOIN  [sys].[tables]			AS	SYSTBL  WITH (NOLOCK)'' + @LineBreak
			  	+	''				      ON  SYSIDX.[object_id]		=	SYSTBL.[object_id]'' + @LineBreak
				+	''			  INNER JOIN  [sys].[schemas]			AS	SYSSCH	 WITH (NOLOCK)'' + @LineBreak
				+	''					  ON  SYSSCH.[schema_id]		=	SYSTBL.[schema_id]'' + @LineBreak
				+	''				   WHERE  SYSIDX.type				=	6'' + @LineBreak
				+	''				     AND  SYSIDX.[name]				=	'''''''''' + @IDXName + '''''''''''' + @LineBreak
				+	''					 AND  SYSTBL.[name]				=	'''''''''' + @TBLName + '''''''''''' + @LineBreak
				+	''					 AND  SYSSCH.[name]				=	'''''''''' + @SCHName + ''''''''''))'' + @LineBreak
				+   ''BEGIN'' + @LineBreak
				+   ''	EXECUTE [BiAdmin].[log].[AddDebugInfo] 
					 @Database='''''''''' + @DBName + ''''''''''
					,@Job='''''''''' + CONVERT(VARCHAR(MAX), @JobID) + ''''''''''
					,@Procedure=''''''''CreateClmStrIdx - START''''''''
					,@Message='''''''''' + QUOTENAME(@IDXName) + '' ON '' + QUOTENAME(@SCHName) + ''.'' + QUOTENAME(@TBLName) + ''''''''''; '' + @LineBreak
				+   '''' + @LineBreak
				+   ''	CREATE NONCLUSTERED COLUMNSTORE INDEX '' + QUOTENAME(@IDXName) + '' ON '' + QUOTENAME(@SCHName) + ''.'' + QUOTENAME(@TBLName) + '' '' + @LineBreak
				+   ''	( '' + @LineBreak
				+   ''		'' + @IDXColumns + '''' + @LineBreak
				+   ''	) WITH (DROP_EXISTING = OFF)'' + IIF(COALESCE(@CSIFGName,@FGName) IS NULL,'''','' ON [''+ COALESCE(@CSIFGName,@FGName) + '']'') + '';'' + @LineBreak
				+   '''' + @LineBreak
				+   ''	EXECUTE [BiAdmin].[log].[AddDebugInfo] 
					 @Database='''''''''' + @DBName + ''''''''''
					,@Job='''''''''' + CONVERT(VARCHAR(MAX), @JobID) + ''''''''''
					,@Procedure=''''''''CreateClmStrIdx - SLUT''''''''
					,@Message='''''''''' + QUOTENAME(@IDXName) + '' ON '' + QUOTENAME(@SCHName) + ''.'' + QUOTENAME(@TBLName) + ''''''''''; '' + @LineBreak
				+	''END'' + @LineBreak
				+   '''''''''					

				+	'	EXEC (@SQL2)'																											+ @LineBreak
				+	'	--PRINT (@SQL2)'																										+ @LineBreak
				+	'	-- ----- Next from Cursor -----'																						+ @LineBreak
				+	'	FETCH NEXT FROM db_csr'																									+ @LineBreak
				+	'		    INTO @BatchID, @CursorJobID, @DBName, @SCHName, @TBLName, @IDXName, @FGName, @CSIFGName, @IDXColumns' + @LineBreak
				+	'END'																														+ @LineBreak
				+	'-- ----- Deallocat -----'																									+ @LineBreak
				+	'CLOSE db_csr'																												+ @LineBreak
				+	'DEALLOCATE db_csr'																											+ @LineBreak
				+	'IF OBJECT_ID(''tempdb..#TmpClmTbl'') IS NOT NULL '																			+ @LineBreak
				+	'	DROP TABLE #TmpClmTbl'																									+ @LineBreak
				+	'-- ----- END -----'																										+ @LineBreak																							+ @LineBreak
	END
	-- ----- Execute Code -----
	--IF(@parmDebug>0) PRINT (@SQL)
	--PRINT @SQL
	EXEC (@SQL)

END