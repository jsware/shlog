# ShLog

A shell script logging framework.

## Introduction to ShLog

The ShLog framework provides a set of logging functions for shell scripts.  Additionally a `shlog` wrapper script is available to capture existing script output into rotating log files without modification.

The logging functions (e.g. ShlogInfo, ShlogWarning, ShlogError) output messages to standard output/error and log these same messages to a rotating set of log files.  Shlog functions for more detailed logging (ShlogConfig, ShlogDebug, ShlogFine, ShlogFiner and ShlogFinest) are also available.

Include the functions into a script using the source command:

```shell
source shloglib.sh
```

The log file name is set using the `SHLOG_FILE` environment variable.  Whether ShLog* statements produce output is controlled by the `SHLOG_LEVEL` variable.  The number and size of log file archives are controlled with `SHLOG_COUNT` and `SHLOG_SIZE` (in KB) variables.  These default to 10 x 1024KB (1MB) files.
