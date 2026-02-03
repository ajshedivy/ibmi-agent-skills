# QSYS2.ACTIVE_JOB_INFO

Returns one row for every active job. Replacement for WRKACTJOB command with elapsed statistics tracking.

**Key Features:**
- View active job details (filtered or all jobs)
- Measure elapsed statistics (reset baseline like WRKACTJOB F10)

**Authorization:**
- `NONE`/`WORK`: None required
- `QTEMP`: *JOBCTL special authority
- `ALL`/`FULL`: *JOBCTL for all columns; QIBM_DB_SQLADM or QIBM_DB_SYSMON for SQL columns

## Syntax

```sql
SELECT * FROM TABLE(QSYS2.ACTIVE_JOB_INFO(
  RESET_STATISTICS => reset-statistics,
  SUBSYSTEM_LIST_FILTER => subsystem-list-filter,
  JOB_NAME_FILTER => job-name-filter,
  CURRENT_USER_LIST_FILTER => current-user-list-filter,
  DETAILED_INFO => detailed-info
)) X
```

## Parameters

| Parameter | Values/Default | Description |
|-----------|----------------|-------------|
| **RESET_STATISTICS** | `YES`/`NO` (default `NO`) | Reset elapsed statistics baseline. First invocation auto-resets. Changing filters also resets |
| **SUBSYSTEM_LIST_FILTER** | Comma-separated list (max 25)<br>Example: `'QBATCH,QINTER'`<br>Default: All | Filter by subsystems |
| **JOB_NAME_FILTER** | `*` (current job)<br>`*ALL` (all jobs, default)<br>`*CURRENT` (jobs with same name)<br>`*SBS` (subsystem monitors)<br>`*SYS` (system jobs)<br>Job name (supports generic) | Filter by job name. Note: `*SYS` requires SUBSYSTEM_LIST_FILTER be null |
| **CURRENT_USER_LIST_FILTER** | Comma-separated list (max 10)<br>Example: `'SCOTTF,ADMIN'`<br>Default: All | Filter by user profiles |
| **DETAILED_INFO** | `NONE` (default) - General info only<br>`WORK` - + Work management<br>`QTEMP` - + QTEMP_SIZE<br>`FULL` - All except QTEMP_SIZE/CLIENT_HOST<br>`ALL` - All columns | Detail level returned |

## Result Set

**All columns are nullable.** Columns vary based on `DETAILED_INFO` parameter.

> **Note:** The DETAILED_INFO level indicates which parameter values (`NONE`, `WORK`, `QTEMP`, `FULL`, `ALL`) can return a non-null value.

### Job Identification
*Available in: NONE, WORK, QTEMP, FULL, ALL*

- **ORDINAL_POSITION** (INTEGER) - Unique row number
- **JOB_NAME** (VARCHAR 28) - Qualified job name
- **JOB_NAME_SHORT** (VARCHAR 10) - Short job name
- **JOB_USER** (VARCHAR 10) - User profile that started the job
- **JOB_NUMBER** (VARCHAR 6) - Job number
- **INTERNAL_JOB_ID** (BINARY 16) - Internal job identifier
- **SUBSYSTEM**, **SUBSYSTEM_LIBRARY_NAME** (VARCHAR 10) - Subsystem details (null for system jobs)
- **AUTHORIZATION_NAME** (VARCHAR 10) - User profile for initial thread (may differ from JOB_USER for profile-swapped jobs)

### Job Type, Status & Function
*Available in: NONE, WORK, QTEMP, FULL, ALL*

- **JOB_TYPE** (VARCHAR 3) - Job type: `ASJ`, `BCH`, `BCI`, `EVK`, `INT`, `M36`, `MRT`, `PDJ`, `PJ`, `RDR`, `SBS`, `SYS`, `WTR`
- **JOB_STATUS** (VARCHAR 4) - Thread status: `CMNW`, `CNDW`, `DEQW`, `DLYW`, `DSPW`, `END`, `EOJ`, `EVTW`, `HLD`, `JVAW`, `LCKW`, `LSPW`, `MSGW`, `MTXW`, `PSRW`, `RUN`, `SEMW`, `THDW` (see IBM docs for full list)
- **FUNCTION_TYPE** (VARCHAR 3) - Function descriptor type: `CMD`, `DLY`, `GRP`, `I/O`, `IDX`, `JVM`, `LOG`, `MNU`, `MRT`, `PGM`, `PRC`, `USR`
- **FUNCTION** (VARCHAR 10) - Last high-level function. If FUNCTION_TYPE is set, value depends on type. Otherwise: `ADLACTJOB`, `ADLTOTJOB`, `CMDENT`, `COMMIT`, `DIRSHD`, `DLTSPF`, `DUMP`, `JOBIDXRCY`, `JOBLOG`, `JOBLOGQRCY`, `PASSTHRU`, `RCLSPLSTG`, `ROLLBACK`, `SPLCLNUP`
- **MEMORY_POOL** (VARCHAR 9) - System pool identifier for job's main storage
- **RUN_PRIORITY** (INTEGER) - Priority 1-99 (1=highest)
- **THREAD_COUNT** (INTEGER) - Active thread count
- **JOB_END_REASON** (VARCHAR 60) - Why job is ending (device error, CPU limit, signal, storage limit, etc.)
- **SERVER_TYPE** (VARCHAR 30) - Server type if job is part of a server

### Resource Usage & Performance
*Available in: NONE, WORK, QTEMP, FULL, ALL*

- **TEMPORARY_STORAGE** (INTEGER) - Current temp storage in MB
- **CPU_TIME** (DECIMAL 20,0) - Total CPU time in milliseconds
- **TOTAL_DISK_IO_COUNT** (DECIMAL 20,0) - Total disk I/O operations (async + sync)
- **ELAPSED_INTERACTION_COUNT** (INTEGER) - Operator interactions during measurement interval (interactive jobs only)
- **ELAPSED_TOTAL_RESPONSE_TIME** (INTEGER) - Total response time in seconds during interval (interactive jobs only)
- **ELAPSED_TOTAL_DISK_IO_COUNT** (DECIMAL 20,0) - Disk I/O during measurement interval
- **ELAPSED_ASYNC_DISK_IO_COUNT** (DECIMAL 20,0) - Async I/O during interval
- **ELAPSED_SYNC_DISK_IO_COUNT** (DECIMAL 20,0) - Sync I/O during interval
- **ELAPSED_CPU_PERCENTAGE** (DECIMAL 10,2) - CPU percentage during interval
- **ELAPSED_CPU_TIME** (DECIMAL 20,0) - CPU time in milliseconds during interval
- **ELAPSED_PAGE_FAULT_COUNT** (DECIMAL 20,0) - Page faults during interval
- **ELAPSED_TIME** (DECIMAL 20,3) - Elapsed seconds since measurement start

### Work Management
*Available in: WORK, FULL, ALL*

- **JOB_DESCRIPTION**, **JOB_DESCRIPTION_LIBRARY** (VARCHAR 10) - Job description
- **JOB_QUEUE**, **JOB_QUEUE_LIBRARY** (VARCHAR 10) - Job queue (batch jobs only)
- **OUTPUT_QUEUE**, **OUTPUT_QUEUE_LIBRARY** (VARCHAR 10) - Default output queue
- **WORKLOAD_GROUP** (VARCHAR 10) - Workload group membership
- **JOB_TYPE_ENHANCED** (VARCHAR 28) - Combined type/subtype: `ALTERNATE_SPOOL_USER`, `AUTOSTART`, `BATCH`, `BATCH_IMMEDIATE`, `BATCH_MRT`, `COMM_PROCEDURE_START_REQUEST`, `INTERACTIVE`, `INTERACTIVE_GROUP`, `INTERACTIVE_SYSREQ`, `INTERACTIVE_SYSREQ_AND_GROUP`, `PRESTART`, `PRESTART_BATCH`, `PRESTART_COMM`, `READER`, `SUBSYSTEM`, `SYSTEM`, `WRITER`
- **JOB_ENTERED_SYSTEM_TIME**, **JOB_ACTIVE_TIME** (TIMESTAMP) - When job entered/started
- **MAXIMUM_ACTIVE_THREADS** (INTEGER) - Max concurrent threads allowed
- **SYSTEM_POOL_ID** (INTEGER) - System pool ID for initial thread
- **POOL_NAME** (VARCHAR 10) - Memory pool name: `*BASE`, `*INTERACT`, `*MACHINE`, `*SHRPOOL1-60`, `*SPOOL`, or number

### Regional Settings
*Available in: WORK, FULL, ALL*

- **CCSID**, **DEFAULT_CCSID** (INTEGER) - Coded character set identifiers
- **SORT_SEQUENCE**, **SORT_SEQUENCE_LIBRARY** (VARCHAR 10) - Sort sequence table
- **LANGUAGE_ID** (CHAR 3) - Language identifier
- **DATE_FORMAT** (CHAR 4) - Date format: `*DMY`, `*JUL`, `*MDY`, `*YMD`
- **DATE_SEPARATOR**, **TIME_SEPARATOR** (CHAR 1) - Format separators
- **DECIMAL_FORMAT** (VARCHAR 6) - Decimal format: `*BLANK`, `I`, `J`
- **TIMEZONE_DESCRIPTION** (VARCHAR 10) - Time zone description *(FULL, ALL only)*
- **TIMEZONE_CURRENT_OFFSET** (INTEGER) - Time zone offset in minutes, adjusted for DST *(FULL, ALL only)*
- **TIMEZONE_FULL_NAME** (VARCHAR 50) - Full time zone name *(FULL, ALL only)*
- **TIMEZONE_ABBREVIATED_NAME** (VARCHAR 10) - Abbreviated time zone name *(FULL, ALL only)*

### Job Identity & Security
*Available in: FULL, ALL*

- **JOB_USER_IDENTITY** (VARCHAR 10) - User profile for authorization checks
- **JOB_USER_IDENTITY_SETTING** (VARCHAR 11) - How identity was set: `APPLICATION`, `DEFAULT`, `SYSTEM`
- **DBCS_CAPABLE** (VARCHAR 3) - DBCS-capable: `YES`, `NO`
- **SIGNAL_STATUS** (VARCHAR 3) - Can receive signals: `YES`, `NO`
- **MESSAGE_REPLY** (VARCHAR 3) - Waiting for message reply: `YES`, `NO`
- **END_STATUS** (VARCHAR 3) - Controlled cancellation issued: `YES`, `NO`
- **CANCEL_KEY**, **EXIT_KEY** (VARCHAR 3) - User pressed key: `YES`, `NO`

### Resource Limits
*Available in: FULL, ALL*

- **PEAK_TEMPORARY_STORAGE** (INTEGER) - Max aux storage used in MB
- **DEFAULT_WAIT** (INTEGER) - Default resource wait time in seconds
- **MAXIMUM_PROCESSING_TIME_ALLOWED** (INTEGER) - Max CPU time in milliseconds
- **MAXIMUM_TEMPORARY_STORAGE_ALLOWED** (INTEGER) - Max temp storage in MB
- **TIME_SLICE** (INTEGER) - Max processor time per thread in milliseconds (8-9999999)
- **PAGE_FAULTS** (BIGINT) - Page faults during current routing step
- **TOTAL_RESPONSE_TIME** (BIGINT) - Total response time in milliseconds (interactive jobs)
- **INTERACTIVE_TRANSACTIONS** (INTEGER) - Operator interaction count
- **DATABASE_LOCK_WAITS**, **NON_DATABASE_LOCK_WAITS**, **INTERNAL_MACHINE_LOCK_WAITS** (INTEGER) - Lock wait counts
- **DATABASE_LOCK_WAIT_TIME**, **NON_DATABASE_LOCK_WAIT_TIME**, **INTERNAL_MACHINE_LOCK_WAIT_TIME** (INTEGER) - Lock wait time in milliseconds

### SQL Activity
*Available in: FULL, ALL*

- **SQL_STATEMENT_TEXT** (VARCHAR 10000) - Last/current SQL statement text
- **SQL_STATEMENT_STATUS** (VARCHAR 8) - SQL status: `ACTIVE`, `COMPLETE`
- **SQL_STATEMENT_START_TIMESTAMP** (TIMESTAMP) - Active statement start time
- **SQL_STATEMENT_NAME** (VARCHAR 128) - SQL statement name
- **SQL_STATEMENT_LIBRARY_NAME**, **SQL_STATEMENT_OBJECT_NAME** (VARCHAR 10) - Statement object details
- **SQL_STATEMENT_OBJECT_TYPE** (VARCHAR 7) - Object type: `*PGM`, `*SQLPKG`, `*SRVPGM`
- **QUERY_OPTIONS_LIBRARY_NAME** (VARCHAR 10) - QAQQINI library
- **SQL_ACTIVATION_GROUP_COUNT** (INTEGER) - Activation groups with SQL
- **SQL_DESCRIPTOR_COUNT** (BIGINT) - Active SQL descriptors
- **SQL_LOB_LOCATOR_COUNT** (INTEGER) - Active LOB locators
- **CLI_HANDLE_COUNT** (BIGINT) - Active CLI handles
- **SQL_SERVER_MODE** (VARCHAR 3) - Using SQL Server Mode: `YES`, `NO`
- **CLIENT_ACCTNG**, **CLIENT_APPLNAME**, **CLIENT_PROGRAMID**, **CLIENT_USERID**, **CLIENT_WRKSTNNAME** (VARCHAR 255) - SQL special register values
- **ROUTINE_TYPE** (CHAR 1) - Current routine type: `F`, `P`
- **ROUTINE_SCHEMA**, **ROUTINE_SPECIFIC_NAME** (VARCHAR 128) - Current routine details

### SQL Cursors
*Available in: FULL, ALL*

- **OPEN_CURSOR_COUNT** (INTEGER) - Currently open cursors
- **FULL_OPEN_CURSOR_COUNT** (BIGINT) - Full opens for job lifetime
- **PSEUDO_OPEN_CURSOR_COUNT** (BIGINT) - Pseudo opens (reused cursors) for lifetime
- **PSEUDO_CLOSED_CURSOR_COUNT** (INTEGER) - Active pseudo closed cursors
- **CQE_CURSOR_COUNT**, **CQE_CURSOR_STORAGE** (INTEGER) - CQE cursor count and storage in MB
- **SQE_CURSOR_COUNT**, **SQE_CURSOR_STORAGE** (INTEGER) - SQE cursor count and storage in MB
- **LARGEST_QUERY_SIZE** (INTEGER) - Largest SQE cursor storage in MB
- **QRO_HASH** (VARCHAR 16) - Query optimizer hash for largest query
- **QRO_HASH_JSON** (CLOB 1M) - JSON array of QRO hashes for queries currently optimizing/running
- **PLAN_IDENTIFIER_JSON** (CLOB 1M) - JSON array of plan identifiers for currently running queries

### Client & Connection Info
*Available in: FULL, ALL*

- **CLIENT_IP_ADDRESS** (VARCHAR 45) - Client IPv4 address
- **CLIENT_PORT** (INTEGER) - Client TCP port
- **CLIENT_HOST** (VARCHAR 255) - Client host name *(ALL only)*
- **INTERFACE_NAME** (VARCHAR 127) - Client database interface name
- **INTERFACE_TYPE** (VARCHAR 63) - Client database interface type
- **INTERFACE_LEVEL** (VARCHAR 63) - Interface level in VVRRMMFP format

### Other
*Available in: QTEMP, FULL, ALL (varies)*

- **QTEMP_SIZE** (INTEGER) - QTEMP storage in MB *(QTEMP, ALL only)*
- **PRESTART_JOB_REUSE_COUNT**, **PRESTART_JOB_MAX_USE_COUNT** (INTEGER) - Prestart job usage (-1 = `*NOMAX`) *(FULL, ALL)*
- **AVAILABLE_RESULT_SETS**, **UNCONSUMED_RESULT_SETS** (INTEGER) - SQL result set counts *(FULL, ALL)*
- **SERVER_MODE_CONNECTING_JOB** (VARCHAR 28) - SQL Server Mode connecting job *(FULL, ALL)*
- **SERVER_MODE_CONNECTING_THREAD** (BIGINT) - Server mode thread ID *(FULL, ALL)*
- **OPEN_FILES** (INTEGER) - Open file count (use QSYS2.OPEN_FILES for details) *(FULL, ALL)*
## Examples

### Example 1: Top 10 consumers of Elapsed I/O

Looking at only QZDASOINIT jobs, find the top 10 consumers of Elapsed I/O.

```sql
SELECT JOB_NAME, AUTHORIZATION_NAME, ELAPSED_TOTAL_DISK_IO_COUNT, ELAPSED_CPU_PERCENTAGE
FROM TABLE(QSYS2.ACTIVE_JOB_INFO(
            JOB_NAME_FILTER => 'QZDASOINIT',
            SUBSYSTEM_LIST_FILTER => 'QUSRWRK')) X
ORDER BY ELAPSED_TOTAL_DISK_IO_COUNT DESC
FETCH FIRST 10 ROWS ONLY;
```

> **Note:** The data in the `ELAPSED_xxx` columns is updated upon each re-execution of the query. Elapsed data will not get returned the first time a query is run for ACTIVE_JOB_INFO for a connection. See the `reset-statistics` parameter for details.

### Example 2: Jobs using the most temporary storage

Find the active jobs using the most temporary storage. Include the most recently executed SQL statement for each target job.

```sql
SELECT JOB_NAME, AUTHORIZATION_NAME, TEMPORARY_STORAGE, SQL_STATEMENT_TEXT
FROM TABLE(QSYS2.ACTIVE_JOB_INFO(DETAILED_INFO => 'ALL')) X
WHERE JOB_TYPE <> 'SYS'
ORDER BY TEMPORARY_STORAGE DESC;
```