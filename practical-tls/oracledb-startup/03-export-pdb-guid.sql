set echo off termout off head off pagesize 0 trimspool on
--set markup csv on
spool /home/oracle/guid.txt
select guid from v$containers;
spool off
