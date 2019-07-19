CREATE VIEW [flw].[ListJobLog]
AS
SELECT     TOP (100) PERCENT flw.JobLog.BatchID, flw.JobLog.Log_ID, flw.JobStatus.Status_Beskrivelse AS Status, flw.JobLog.Success, flw.JobListe.Aktiv AS [JobListe Aktiv], 
                      sysjobs_JobID.name AS JobName, flw.JobType.JobType_Beskrivelse, flw.JobLog.OprettetDato, flw.JobLog.JobID, flw.JobLog.Log_Message, 
                      sysjobs_Caller.name AS CallerJobName, flw.JobLog.CallerSPName, flw.JobLog.DebugTxt
FROM         flw.JobLog LEFT OUTER JOIN
                      dbo.sysjobs AS sysjobs_Caller ON flw.JobLog.CallerJobID = sysjobs_Caller.job_id LEFT OUTER JOIN
                      dbo.sysjobs AS sysjobs_JobID ON sysjobs_JobID.job_id = flw.JobLog.JobID LEFT OUTER JOIN
                      flw.JobStatus ON flw.JobLog.StatusID = flw.JobStatus.Status_ID LEFT OUTER JOIN
                      flw.JobListe ON flw.JobListe.JobID = flw.JobLog.JobID LEFT OUTER JOIN
                      flw.JobType ON flw.JobListe.JobType_ID = flw.JobType.JobType_ID
ORDER BY flw.JobLog.BatchID DESC, flw.JobLog.Log_ID