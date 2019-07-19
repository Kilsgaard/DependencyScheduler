
CREATE VIEW [flw].[ListAfhængighedmedNavn]
AS
SELECT     flw.JobAfhaengighed.ParentJobID, ParentSysJobs.name AS ParentName, ParentJobListe.Aktiv AS ParentAktiv, ParentSysJobs.enabled AS ParentEnabled, 
                      ParentJobListe.BatchStartJob AS ParentBatchStartJob, ParentJobListe.BatchStopJob AS ParentBatchStopJob, flw.JobAfhaengighed.ChildJobID, 
                      ChildSysJobs.name AS ChildName, ChildJobListe.Aktiv AS ChildAktiv, ChildSysJobs.enabled AS ChildEnabled, ChildJobListe.BatchStartJob AS ChildBatchStartJob, 
                      ChildJobListe.BatchStopJob AS ChildBatchStopJob
FROM         flw.JobAfhaengighed INNER JOIN
                      flw.JobListe AS ParentJobListe ON flw.JobAfhaengighed.ParentJobID = ParentJobListe.JobID INNER JOIN
                      dbo.sysjobs AS ParentSysJobs ON ParentJobListe.JobID = ParentSysJobs.job_id INNER JOIN
                      flw.JobListe AS ChildJobListe ON flw.JobAfhaengighed.ChildJobID = ChildJobListe.JobID INNER JOIN
                      dbo.sysjobs AS ChildSysJobs ON ChildJobListe.JobID = ChildSysJobs.job_id