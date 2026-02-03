# QSYS2.JOB_INFO

Returns one row for each job meeting selection criteria. Replacement for WRKUSRJOB, WRKSBSJOB, WRKSBMJOB commands.

**Authorization:** None required

## Syntax

```sql
SELECT * FROM TABLE(QSYS2.JOB_INFO(
  JOB_STATUS_FILTER => job-status-filter,
  JOB_TYPE_FILTER => job-type-filter,
  JOB_SUBSYSTEM_FILTER => job-subsystem-filter,
  JOB_USER_FILTER => job-user-filter,
  JOB_SUBMITTER_FILTER => job-submitter-filter,
  JOB_NAME_FILTER => job-name-filter
)) X
```

## Parameters (all default to `*ALL`)

| Parameter | Values | Description |
|-----------|--------|-------------|
| **JOB_STATUS_FILTER** | `*ALL`<br>`*ACTIVE`<br>`*JOBQ`<br>`*OUTQ` | All jobs<br>Active jobs (use ACTIVE_JOB_INFO for more details)<br>Jobs waiting on job queue<br>Jobs completed with output on output queue |
| **JOB_TYPE_FILTER** | `*ALL`<br>`*BATCH`<br>`*INTERACT` | All job types<br>Batch jobs only<br>Interactive jobs only |
| **JOB_SUBSYSTEM_FILTER** | `*ALL`<br>subsystem name | All subsystems<br>Specific subsystem (active jobs only) |
| **JOB_USER_FILTER** | `*ALL`<br>`*USER`<br>USER<br>user name | All users<br>Job name user portion<br>Current user (default)<br>Specific user |
| **JOB_SUBMITTER_FILTER** | `*ALL`<br>`*JOB`<br>`*USER`<br>`*WRKSTN` | All submitted jobs<br>Submitted by current job<br>Submitted by same user profile<br>Submitted from same workstation |
| **JOB_NAME_FILTER** | `*ALL`<br>job name | All job names<br>Specific job name |

## Important Notes

- **Restriction:** If `JOB_SUBMITTER_FILTER` is not `*ALL`, then `JOB_SUBSYSTEM_FILTER`, `JOB_USER_FILTER`, and `JOB_NAME_FILTER` must be `*ALL`
- Jobs with SBMJOB DSPSBMJOB(*NO) are not returned
- **For WRKUSRJOB equivalence:** Add `WHERE JOB_TYPE NOT IN ('SBS','SYS','RDR','WTR')`
- **For WRKSBSJOB SBS(*OUTQ) or SBS(*ALL):** Add `WHERE JOB_TYPE NOT IN ('SBS','SYS')`

## CL Command Equivalents

| CL Command | SQL Equivalent |
|------------|----------------|
| `WRKSBMJOB SBMFROM(*USER)` | `JOB_SUBMITTER_FILTER => '*USER', JOB_USER_FILTER => '*ALL'` |
| `WRKSBSJOB SBS(QBATCH)` | `JOB_SUBSYSTEM_FILTER => 'QBATCH', JOB_USER_FILTER => '*ALL'` |
| `WRKSBSJOB SBS(*JOBQ)` | `JOB_STATUS_FILTER => '*JOBQ', JOB_USER_FILTER => '*ALL'` |
| `WRKUSRJOB` | `JOB_INFO()` + `WHERE JOB_TYPE NOT IN ('SBS','SYS','RDR','WTR')` |
| `WRKUSRJOB JOBTYPE(*INTERACT)` | `JOB_TYPE_FILTER => '*INTERACT'` + `WHERE JOB_TYPE NOT IN ('SBS','SYS','RDR','WTR')` |

## Key Result Columns

**All columns are nullable.** Full column list available in IBM i documentation.

### Job Identification
- **JOB_NAME** (VARCHAR 28) - Qualified job name
- **JOB_NAME_SHORT** (VARCHAR 10) - Short job name
- **JOB_USER** (VARCHAR 10) - User profile that started the job
- **JOB_NUMBER** (VARCHAR 6) - Job number
- **JOB_INFORMATION** (VARCHAR 12) - `YES` or `NO` (if NO, all other columns are null)
- **INTERNAL_JOB_ID** (BINARY 16) - Internal job identifier

### Status and Type
- **JOB_STATUS** (VARCHAR 6) - `ACTIVE`, `JOBQ`, `OUTQ`
- **JOB_TYPE** (VARCHAR 3) - ASJ, BCH, BCI, EVK, INT, M36, MRT, PDJ, PJ, RDR, SBS, SYS, WTR
- **JOB_TYPE_ENHANCED** (VARCHAR 28) - Detailed type (AUTOSTART, BATCH, BATCH_IMMEDIATE, INTERACTIVE, PRESTART, etc.)
- **JOB_SUBSYSTEM** (VARCHAR 10) - Subsystem name

### Timing
- **JOB_DATE** (VARCHAR 10) - Job date in ISO format or `SYSVAL`
- **JOB_ENTERED_SYSTEM_TIME** (TIMESTAMP) - When job entered system
- **JOB_SCHEDULED_TIME** (TIMESTAMP) - Scheduled activation time
- **JOB_ACTIVE_TIME** (TIMESTAMP) - When job began running
- **JOB_END_TIME** (TIMESTAMP) - When job completed

### Configuration & Resources
- **JOB_DESCRIPTION**, **JOB_DESCRIPTION_LIBRARY** (VARCHAR 10) - Job description details
- **JOB_ACCOUNTING_CODE** (VARCHAR 15) - Resource tracking identifier
- **SERVER_TYPE** (VARCHAR 30) - Server type if applicable
- **PEAK_TEMPORARY_STORAGE** (INT) - Max aux storage used (MB)
- **MAXIMUM_TEMPORARY_STORAGE_ALLOWED** (INT) - Max aux storage limit (MB)
- **MAXIMUM_PROCESSING_TIME_ALLOWED** (INT) - Max CPU time limit (ms)
- **DEFAULT_WAIT** (INT) - Default wait time for resources (sec)
- **TIME_SLICE** (INT) - Max processor time per thread (ms, 8-9999999)
- **ALLOW_MULTIPLE_THREADS** (VARCHAR 3) - `YES`/`NO`

### Submitter & Completion
- **SUBMITTER_JOB_NAME** (VARCHAR 28) - Submitter's qualified job name
- **SUBMITTER_MESSAGE_QUEUE**, **SUBMITTER_MESSAGE_QUEUE_LIBRARY** (VARCHAR 10) - Completion message queue
- **COMPLETION_STATUS** (VARCHAR 8) - `NORMAL`/`ABNORMAL`
- **JOB_END_REASON** (VARCHAR 60) - Why job ended (device error, CPU limit, signal, etc.)
- **JOB_END_SEVERITY** (SMALLINT) - Message severity that ends batch jobs

### Job Queues
- **JOB_QUEUE_NAME**, **JOB_QUEUE_LIBRARY** (VARCHAR 10) - Job queue details
- **JOB_QUEUE_STATUS** (VARCHAR 9) - `HELD`, `RELEASED`, `SCHEDULED`
- **JOB_QUEUE_PRIORITY** (SMALLINT) - Priority 0-9 (0=highest)
- **JOB_QUEUE_TIME** (TIMESTAMP) - When placed on queue
- **JOB_MESSAGE_QUEUE_MAXIMUM_SIZE** (SMALLINT) - Max queue size (MB, 2-64)
- **JOB_MESSAGE_QUEUE_FULL_ACTION** (VARCHAR 8) - `*NOWRAP`, `*WRAP`, `*PRTWRAP`

### Regional & Format Settings
- **CCSID** (INT), **CHARACTER_IDENTIFIER_CONTROL** (VARCHAR 9) - Character set
- **LANGUAGE_ID** (CHAR 3), **COUNTRY_ID** (CHAR 2) - Language/country
- **DATE_FORMAT** (CHAR 4) - `*DMY`, `*JUL`, `*MDY`, `*YMD`
- **DATE_SEPARATOR**, **TIME_SEPARATOR** (CHAR 1) - Format separators
- **TIME_ZONE_DESCRIPTION_NAME** (VARCHAR 10) - Time zone
- **DECIMAL_FORMAT** (VARCHAR 6) - `*BLANK`, `I`, `J`
- **SORT_SEQUENCE_NAME**, **SORT_SEQUENCE_LIBRARY** (VARCHAR 10) - Sort sequence

### Logging & Messaging
- **MESSAGE_LOGGING_LEVEL** (SMALLINT) - 0-4 (0=none, 4=all with trace)
- **MESSAGE_LOGGING_SEVERITY** (SMALLINT) - Severity threshold 0-99
- **MESSAGE_LOGGING_TEXT** (VARCHAR 7) - `*MSG`, `*NOLIST`, `*SECLVL`
- **LOG_CL_PROGRAM_COMMANDS** (VARCHAR 4) - `*YES`/`*NO`
- **STATUS_MESSAGE** (VARCHAR 7) - `*NONE`/`*NORMAL`
- **INQUIRY_MESSAGE_REPLY** (VARCHAR 8) - `*RQD`, `*DFT`, `*SYSRPYL`
- **BREAK_MESSAGE** (VARCHAR 7) - `*HOLD`, `*NORMAL`, `*NOTIFY`
- **JOB_LOG_OUTPUT** (VARCHAR 10) - `*JOBEND`, `*JOBLOGSVR`, `*PND`
- **JOB_LOG_PENDING** (VARCHAR 3) - `YES`/`NO`

### Output & Print
- **OUTPUT_QUEUE_NAME**, **OUTPUT_QUEUE_LIBRARY** (VARCHAR 10) - Output queue
- **OUTPUT_QUEUE_PRIORITY** (SMALLINT) - 0-9 (0=highest)
- **SPOOLED_FILE_ACTION** (VARCHAR 7) - `*DETACH`/`*KEEP`
- **PRINTER_DEVICE_NAME** (VARCHAR 10) - Printer device
- **PRINT_KEY_FORMAT** (VARCHAR 7) - `*NONE`, `*PRTBDR`, `*PRTHDR`, `*PRTALL`
- **PRINT_TEXT** (VARCHAR 30) - Text printed on each page

### Interactive & Device
- **DEVICE_NAME** (VARCHAR 10) - Device for interactive jobs
- **DEVICE_RECOVERY_ACTION** (VARCHAR 13) - `*DSCENDRQS`, `*DSCMSG`, `*ENDJOB`, `*ENDJOBNOLIST`, `*MSG`

### Advanced
- **JOB_SWITCHES** (CHAR 8) - Current job switches
- **ROUTING_DATA** (VARCHAR 80) - Routing step data
- **DDM_CONVERSATION** (VARCHAR 5) - `*DROP`/`*KEEP`
- **MODE_NAME** (VARCHAR 8) - APPC mode name
- **UNIT_OF_WORK_ID** (CHAR 24) - UOW ID for tracking across systems

## Examples

```sql
-- Find all interactive jobs
SELECT * FROM TABLE(QSYS2.JOB_INFO(JOB_TYPE_FILTER => '*INTERACT')) X;

-- Find jobs on JOBQ for user SCOTTF
SELECT * FROM TABLE(QSYS2.JOB_INFO(JOB_USER_FILTER => 'SCOTTF', JOB_STATUS_FILTER => '*JOBQ')) X;

-- Find batch jobs on job queues
SELECT * FROM TABLE(QSYS2.JOB_INFO(JOB_TYPE_FILTER => '*BATCH', JOB_STATUS_FILTER => '*JOBQ')) X;

-- Find jobs in QBATCH subsystem
SELECT * FROM TABLE(QSYS2.JOB_INFO(JOB_SUBSYSTEM_FILTER => 'QBATCH', JOB_USER_FILTER => '*ALL')) X;

-- Find jobs submitted by current user
SELECT * FROM TABLE(QSYS2.JOB_INFO(JOB_SUBMITTER_FILTER => '*USER', JOB_USER_FILTER => '*ALL')) X;
```