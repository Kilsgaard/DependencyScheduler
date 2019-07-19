

CREATE VIEW [flw].[ListJobs]
AS
SELECT TOP 100 PERCENT    
dbo.syscategories.name AS [Job Categori], 
dbo.sysjobs.name AS [Job Navn], 
flw.JobListe.JobID AS [Job ID], 
flw.JobStatus.Status_Beskrivelse AS [Job Status], 
flw.JobType.JobType_Beskrivelse AS [Job Beskrivelse],
dbo.sysjobs.enabled AS [sysJob Aktiv], 
flw.JobListe.Aktiv AS [Job Aktiv], 
flw.JobListe.BatchStartJob, 
flw.JobListe.BatchStopJob, 
flw.JobListe.[Kommentar] AS [Kommentar],
dbo.syscategories.name AS [JobKategori], 
dbo.sysjobs.name AS [JobNavn], 
flw.JobListe.JobID AS [JobID], 
flw.JobStatus.Status_Beskrivelse AS [JobStatus], 
flw.JobType.JobType_Beskrivelse AS [JobBeskrivelse],
dbo.sysjobs.enabled AS [sysJobAktiv], 
flw.JobListe.Aktiv AS [JobAktiv]
FROM flw.JobListe 
INNER JOIN dbo.sysjobs 
ON flw.JobListe.JobID = dbo.sysjobs.job_id 
INNER JOIN flw.JobType 
ON flw.JobListe.JobType_ID = flw.JobType.JobType_ID 
INNER JOIN flw.JobStatus 
ON flw.JobListe.Status_ID = flw.JobStatus.Status_ID 
INNER JOIN dbo.syscategories 
ON dbo.sysjobs.category_id = dbo.syscategories.category_id
WHERE     (dbo.syscategories.name = N'BI-drift')
ORDER BY [Job Categori], dbo.sysjobs.name
GO
EXECUTE sp_addextendedproperty @name = N'MS_DiagramPaneCount', @value = 2, @level0type = N'SCHEMA', @level0name = N'flw', @level1type = N'VIEW', @level1name = N'ListJobs';


GO
EXECUTE sp_addextendedproperty @name = N'MS_DiagramPane2', @value = N'      Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
', @level0type = N'SCHEMA', @level0name = N'flw', @level1type = N'VIEW', @level1name = N'ListJobs';


GO
EXECUTE sp_addextendedproperty @name = N'MS_DiagramPane1', @value = N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "JobListe (flw)"
            Begin Extent = 
               Top = 21
               Left = 489
               Bottom = 210
               Right = 640
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "sysjobs"
            Begin Extent = 
               Top = 9
               Left = 233
               Bottom = 302
               Right = 448
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "JobType (flw)"
            Begin Extent = 
               Top = 189
               Left = 755
               Bottom = 282
               Right = 935
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "JobStatus (flw)"
            Begin Extent = 
               Top = 0
               Left = 748
               Bottom = 108
               Right = 918
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "syscategories"
            Begin Extent = 
               Top = 166
               Left = 25
               Bottom = 274
               Right = 177
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
   ', @level0type = N'SCHEMA', @level0name = N'flw', @level1type = N'VIEW', @level1name = N'ListJobs';

