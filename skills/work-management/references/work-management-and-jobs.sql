--
-- Author: Scott Forstie
-- Date:   November, 2025
--
--
-- I'm getting lots of questions about how to use SQL to find jobs.
--
-- We have two primary SQL services for this topic: ACTIVE_JOB_INFO and JOB_INFO
-- They do similar things, but return different detail.
-- For both topics, it is a best practice to use as many of the optional UDTF filters as possible.
-- By using the UDTF filters instead of predicates on the WHERE clause, the performance of
-- your queries will likely be in the best possible range.
--
-- Below, you'll find some working examples to get you started...
--
stop;
--
-- Support pages that list out every enhancement, including which IBM i operating system 
-- releases include the enhancement.
--
-- ACTIVE_JOB_INFO
-- https://www.ibm.com/support/pages/node/1128579
--
-- JOB_INFO
-- https://www.ibm.com/support/pages/node/1128615
--
stop;
-- =============================================================================================
-- =============================================================================================
--                                  Active Job Info - Examples
-- =============================================================================================
-- =============================================================================================

--
-- Active job information (only Work Management detail) for the current connection
--
SELECT *
  FROM TABLE (
      qsys2.active_job_info(job_name_filter => '*')
    );
stop;

--
-- Active job information (complete detail) for the current connection
--
SELECT *
  FROM TABLE (
      qsys2.active_job_info(job_name_filter => '*', detailed_info => 'ALL')
    );
stop;

--
-- Examine the top CPU consumers
--
SELECT job_name, authorization_name AS user_name, cpu_time
  FROM TABLE (
      qsys2.active_job_info(subsystem_list_filter => 'QUSRWRK,QBATCH,QSYSWRK')
    )
  ORDER BY cpu_time DESC
  LIMIT 10;
stop;

--
-- Find Tim's Active Jobs 
--
SELECT *
  FROM TABLE (
      qsys2.active_job_info(
        reset_statistics         => 'NO', 
        subsystem_list_filter    => '', 
        job_name_filter          => '*ALL',
        current_user_list_filter => 'TIMMR', 
        detailed_info            => 'ALL')
    )
  ORDER BY subsystem, run_priority, job_name_short, job_number
  LIMIT 101 OFFSET 0;
stop;

--
-- description: Look for long-running SQL statements for a subset of users
--
select job_name, authorization_name as "User",
       timestampdiff(
         2, cast(current timestamp - sql_statement_start_timestamp as char(22)))
         as execution_seconds,
       timestampdiff(
         4, cast(current timestamp - sql_statement_start_timestamp as char(22)))
         as execution_minutes,
       timestampdiff(
         8, cast(current timestamp - sql_statement_start_timestamp as char(22)))
         as execution_hours, sql_statement_text, j.*
  from table (
      qsys2.active_job_info( detailed_info => 'ALL' , current_user_list_filter => 'TIMMR,SCOTTF' )
    ) j
  where sql_statement_status = 'ACTIVE'
  order by 2 desc
  limit 30;
stop;  

--
-- description: Find active jobs using the most temporary storage.
--
select job_name, authorization_name, temporary_storage, sql_statement_text, j.*
  from table (
      qsys2.active_job_info(detailed_info => 'ALL')
    ) j
  where job_type <> 'SYS'
  order by temporary_storage desc;
stop;

--
-- Find jobs with active SQL statements being executed
--
SELECT job_name, authorization_name AS user_name, cpu_time, 
       sql_statement_status, TIMESTAMPDIFF(2, CAST(CURRENT TIMESTAMP - sql_statement_start_timestamp AS CHAR(22))) AS execution_seconds,
       sql_statement_start_timestamp,  sql_statement_text 
  FROM TABLE (
      qsys2.active_job_info(
        reset_statistics => 'NO', subsystem_list_filter => '', job_name_filter => '*ALL',
        current_user_list_filter => '', detailed_info => 'ALL')
    )
  WHERE sql_statement_start_timestamp IS NOT null
  ORDER BY sql_statement_start_timestamp ASC;  
stop;

--
-- description: Find active jobs using the most QTEMP storage.
--
select job_name, authorization_name, QTEMP_SIZE, sql_statement_text, j.*
  from table (
      qsys2.active_job_info(detailed_info => 'QTEMP')
    ) j
  where job_type <> 'SYS'
  order by QTEMP_SIZE desc;
stop;

--
-- description: Identify Host Server jobs currently using >10 Meg of QTEMP
--
SELECT qtemp_size, job_name,
   internal_job_id, subsystem, subsystem_library_name, authorization_name, job_type,
   function_type, "FUNCTION", job_status, memory_pool, run_priority, thread_count,
   temporary_storage, cpu_time, total_disk_io_count, elapsed_interaction_count,
   elapsed_total_response_time, elapsed_total_disk_io_count,
   elapsed_async_disk_io_count, elapsed_sync_disk_io_count, elapsed_cpu_percentage,
   elapsed_cpu_time, elapsed_page_fault_count, job_end_reason, server_type, elapsed_time
FROM TABLE(qsys2.active_job_info(
  subsystem_list_filter => 'QUSRWRK', 
  job_name_filter       => 'QZDASOINIT', 
  detailed_info         => 'QTEMP'))
WHERE qtemp_size > 10; 
stop; 

--
-- Find active QSQSRVR jobs and the owning application job
--
with tt (authorization_name, job_name, cpu_time, total_disk_io_count) as (
    select authorization_name, job_name, cpu_time, total_disk_io_count
      from table (
          qsys2.active_job_info(
            subsystem_list_filter => 'QSYSWRK', job_name_filter => 'QSQSRVR')
        ) x
  )
  select authorization_name, ss.message_text, job_name, cpu_time, total_disk_io_count
    from tt, table (
           qsys2.joblog_info(job_name)
         ) ss
    where message_id = 'CPF9898' and
          from_program = 'QSQSRVR'
    order by cpu_time desc;
stop;

--
-- Find the top 4 consumers of temporary storage, by memory pool
--
with top_consumers (job_name, memory_pool, authorization_name, function_type, function,
      temporary_storage, rank) as (
    select job_name, memory_pool, authorization_name, function_type, function,
           temporary_storage, rank() over (
             partition by memory_pool
             order by temporary_storage desc
           )
      from table (
          qsys2.active_job_info()
        ) x
      where job_type <> 'SYS'
  )
  select job_name, memory_pool, authorization_name,
         function_type concat '-' concat function as function, temporary_storage
    from top_consumers
    where rank in (1, 2, 3, 4)
    order by memory_pool desc;
stop; 
--
-- description: Find the jobs that are encountering the most lock contention
--
select job_name, database_lock_waits, non_database_lock_waits,
       database_lock_waits + non_database_lock_waits as total_lock_waits, j.*
  from table (
      qsys2.active_job_info(detailed_info => 'ALL')
    ) j
  order by total_lock_waits desc
  limit 20;
stop;

--
-- Review active jobs, that utilize a workload group
--
select w.*, b.*
  from QSYS2.WORKLOAD_GROUP_INFO w, lateral (
         select a.*
           from table (
               qsys2.active_job_info(DETAILED_INFO => 'ALL')
             ) a
           where WORKLOAD_GROUP = w.workload_group
       ) b;
stop;


-- =============================================================================================
-- =============================================================================================
--                                        Job Info - Examples
-- =============================================================================================
-- =============================================================================================

--
-- Find jobs sitting on a job queue, waiting to run
--
SELECT *
  FROM TABLE (
      qsys2.job_info(job_status_filter => '*JOBQ')
    );
stop;

--
-- Find all occurrences of jobs with the job name SCPF
--
SELECT *
  FROM TABLE (
      qsys2.job_info(job_name_filter => 'SCPF', job_user_filter => '*ALL')
    );
stop;

--
-- Find jobs submitted from the current connection
--
cl:SBMJOB CMD(dlyjob dly(44)) LOG(*JOBD *JOBD *SECLVL);
SELECT *
  FROM TABLE (
      qsys2.job_info(job_submitter_filter => '*JOB', job_user_filter => '*ALL')
    );
stop;

--
-- Review the prestart job statistics for all active prestart jobs
--
with pjs (sbslib, sbs, pgmlib, pgm, pj) as (
       -- active subsystems that have prestart jobs
       select subsystem_description_library, subsystem_description,
              prestart_job_program_library, prestart_job_program, prestart_job_name
         from qsys2.prestart_job_info
         where subsystem_active = 'YES'
     ),
     active_pjs (sbslib, sbs, pgmlib, pgm, pj) as (
       -- active pjs
       select distinct sbslib, sbs, pgmlib, pgm, pj
         from pjs,
              lateral (
                select *
                  from table (
                      qsys2.job_info(
                        job_status_filter => '*ACTIVE', job_subsystem_filter => sbs,
                        job_user_filter => '*ALL')
                    )
                  where job_type_enhanced = 'PRESTART_BATCH'
                        and trim(
                          substr(job_name, locate_in_string(job_name, '/', 1, 2) + 1, 10))
                        = pj
              ) xpj
     )
     -- active pjs and statistics
  select sbs, pgmlib concat '/' concat pgm as pgm, current_jobs, average_jobs,
         peak_jobs, current_inuse_jobs, average_inuse_jobs, peak_inuse_jobs,
         current_wait_requests, average_wait_requests, peak_wait_requests,
         average_wait_time, accepted_requests, rejected_requests
    from active_pjs, lateral (
           select *
             from table (
                 qsys2.prestart_job_statistics(sbs, pgmlib, pgm)
               )
         )
    order by 1, 2, 3;
stop;

--
-- Examine the index advice where MTIs have been used 
-- since the last IPL
--      
WITH last_ipl(ipl_time)
   AS (SELECT job_entered_system_time
          FROM TABLE(qsys2.job_info(job_status_filter => '*ACTIVE', 
                                    job_user_filter   => 'QSYS')) x
          WHERE job_name = '000000/QSYS/SCPF')
   SELECT mti_used, mti_created, i.*
      FROM last_ipl, qsys2.sysixadv i
      WHERE last_mti_used > ipl_time OR
            last_mti_used_for_stats > ipl_time
      order by mti_used desc;
stop;

--
-- Examine history log messages since the previous IPL and
-- determine whether the next IPL will be abnormal or normal
--
WITH last_ipl(ipl_time)
   AS (SELECT job_entered_system_time
          FROM TABLE(qsys2.job_info(job_status_filter => '*ACTIVE',
             job_user_filter => 'QSYS')) x
          WHERE job_name = '000000/QSYS/SCPF'), 
   abnormal(abnormal_count) 
   AS (SELECT COUNT(*)
          FROM last_ipl, 
          TABLE(qsys2.history_log_info(ipl_time, CURRENT TIMESTAMP)) x
          WHERE message_id IN ('CPC1225'))
   SELECT
      CASE
         WHEN abnormal_count = 0
            THEN 'NEXT IPL WILL BE NORMAL'
            ELSE 'NEXT IPL WILL BE ABNORMAL - ABNORMAL END COUNT: ' 
               concat abnormal_count
      END AS next_ipl_indicator FROM abnormal ; 
stop;

--
-- Find all interactive jobs
--
SELECT *
  FROM TABLE (
      qsys2.job_info(job_type_filter => '*INTERACT')
    ) x;
stop;
