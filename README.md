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

## Additional ShLogging environment variables

The `SHLOG_WRITERS` variable is a space separated list of functions called to write each log message.  By default it uses `ShLog2File` and `ShLog2StdOut`.  An additional function `ShLog2StdErr` is available as an alternative to `ShLog2StdOut` if your script is designed to output data to stdout so shlogging needs to output to a different file handle.

The ShLogLevel function can set `SHLOG_LEVEL` using more memorable text values:
  * `ERROR` (-3) for errors only;
  * `WARNING` (-2) for warnings and above;
  * `NOTICE` (-1) for notices and above;
  * `INFO` (0) for information and above (the default);
  * `CONFIG` (1) for config settings and above;
  * `DEBUG` (2) for debug statements and above;
  * `FINE` (3) for fine detailed statements;
  * `FINER` (4) for finer details statements;
  * `FINEST` (5) for the finest level of detail;
  * `ALL` is the same as FINEST.

Additionally the `SHLOG_FD` environment variable can be used to specify a file handle (the default is 9) used to write to the current log file.  If handle 9 is used elsewhere, set this to use a different handle.

The environment variables are set to their default as required if not set to a different value first.

## ShLogging functions

Scripts use the following functions to record logging statements:
* `ShLogError` outputs messages prefixed with `ERROR:` to *stderr*;
* `ShLogWarning` outputs messages prefixed with `WARNING:` to *stderr*;
* `ShLogNotice` outputs messages prefixed with `NOTICE:` to *stdout*;
* `ShLogInfo` outputs messages without a prefix to stdout;
* `ShLogConfig` outputs configuration messages to stdout;
* `ShLogDebug` outputs more detailed debugging to stdout;
* `ShLogFine` outputs fine grained messages to stdout;
* `ShLogFiner` outputs more detailed messages to stdout;
* `ShLogFinest` outputs the finest messages to stdout.

Log messages can be passed via command line parameters (e.g. `ShLogInfo "Hello Wordl!"`) or output can be piped to each ShLog statement using the `pipe` option: `cat ./file.txt | ShLogDebug --pipe`.

## Instrumenting your functions

Functions can be instrumented with `ShLogEnter` and `ShLogLeave`.  For example:

```shell
source shloglib.sh

MyFunction() {
  ShLogEnter $FUNCNAME $@
  local rc=0

  ShLogInfo "Hello $@!"
  ...

  ShLogLeave $FUNCNAME returns $rc
  return $rc
}

ShLogLevel ALL
MyFunction 1 2 3 4 World
```
produces the log output with messages inside the function indented inline with the function name.
```
Logging level ALL
->MyFunction 1 2 3 4
  Hello 1 2 3 4 World!
<-MyFunction returns 0
```
Nested functions indent further.  Indentation only occurs if `ShLogEnter` and `ShLogLeave` statements produce output.

## Using the `shlog` wrapper script

The `shlog` wrapper script can capture script output to a rotating set of log files without modification of the original script.

The `shlog` wrapper script takes the following options:

```shell
Usage: shlog [Options] [-v] [-x] Command [CommandArguments]
Run a command, logging output to rotating log files.

Options:
  -b Run script in background (Default foreground).
  -c Log file count (Default 10).
  -f Log file name  (Default ~/{Script}.log).
  -q Quiet (No terminal input/output).
  -s Log file size in KB (Default 1MB).

  -v Verbose.
  -x Debug.
```

Arguments control the name, size and number of rotating log files.  Additionally the script can be run in the background (using the `-b` option), or run in quiet mode (using the `-q` option).

The `shlog` script can be run in verbose, or debug to output progression of the `shlog` wrapper script (this does not affect the output of the logged script - this could be run in quiet mode).
