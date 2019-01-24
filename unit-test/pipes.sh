#!/usr/bin/env bash
###
# @file pipes.sh Test piped ShLogging functions.
#
# Copyright 2016 John Scott
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
set -euo pipefail

# Exit script due to unexpected error.
die() {
  local rc=$?
  echo "ERROR: $* (RC $rc)" >&2
  echo Testing pipe logging FAILED! >&2
  test $rc -gt 0 || rc=1
  exit $rc
}

# Direct verbose output to /dev/null...
exec 3>/dev/null

# Parse arguments...
while getopts :vx- OPT; do
	case $OPT in
		v)	exec 3>&2;;	# Redirect verbose output to stderr.
		x)	set -x;;	# Turn bash debugging on.
		-)	break;;		# No more options.

		:)	echo "ERROR: Required parameter for -$OPTARG missing." >&2; exit 64;;
		\?)	echo "ERROR: Invalid option -$OPTARG specified." >&2; exit 64;;
		*)	echo "ERROR: Option -$OPT not yet implemented." >&2; exit 64;;
	esac
done
shift $(( $OPTIND - 1 ))

echo Testing pipe to ShLogging functions...
source ${0%/*}/../scripts/shloglib.sh || die Sourcing shloglib.sh failed.

export SHLOG_FILE=/tmp/shlog.log
unset SHLOG_SIZE
unset SHLOG_COUNT

rm -f $SHLOG_FILE* || die Log file setup
ShLogLevel all >/dev/null || die ShLogLevel all failed.

test "`echo Test $$ | ShLogError   --pipe 2>&1`" == "ERROR: Test $$"   || die ShLogError Test unexpected output
test "`echo Test $$ | ShLogWarning --pipe 2>&1`" == "WARNING: Test $$" || die ShLogWarning Test unexpected output
test "`echo Test $$ | ShLogNotice  --pipe 2>&1`" == "NOTICE: Test $$"  || die ShLogWarning Test unexpected output
test "`echo Test $$ | ShLogInfo    --pipe 2>&1`" == "Test $$"          || die ShLogInfo Test unexpected output
test "`echo Test $$ | ShLogConfig  --pipe 2>&1`" == "Test $$"          || die ShLogConfig Test unexpected output
test "`echo Test $$ | ShLogDebug   --pipe 2>&1`" == "Test $$"          || die ShLogDebug Test unexpected output
test "`echo Test $$ | ShLogFine    --pipe 2>&1`" == "Test $$"          || die ShLogFine Test unexpected output
test "`echo Test $$ | ShLogFiner   --pipe 2>&1`" == "Test $$"          || die ShLogFiner Test unexpected output
test "`echo Test $$ | ShLogEnter   --pipe 2>&1`" == "->Test $$"        || die ShLogEnter Test unexpected output
test "`echo Test $$ | ShLogLeave   --pipe 2>&1`" == "<-Test $$"        || die ShLogLeave Test unexpected output
test "`echo Test $$ | ShLogFinest  --pipe 2>&1`" == "Test $$"          || die ShLogFinest Test unexpected output

cat $SHLOG_FILE
echo Testing pipe to ShLogging functions PASSED.

exit 0
