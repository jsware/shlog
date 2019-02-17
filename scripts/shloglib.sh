#!/usr/bin/env bash
###
# @file shloglib.sh A set of logging functions.
#
# Copyright 2019 John Scott
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

# Log File settings...
#SHLOG_FILE		The name of the log file.
#SHLOG_FD		The file descriptor used to open the log file.
#SHLOG_COUNT	The number of log archives to rotate.
#SHLOG_SIZE		The size of log archives in KB.
#SHLOG_LEVEL	The logging level at which to record log entries.
#SHLOG_WRITERS	A space separated list of writer functions with parameters:

# 1:Level Text; 2:Log Message
ShLog () {
	local ts= writer=

	for writer in ${SHLOG_WRITERS:=ShLog2File ShLog2StdOut}; do
		$writer "${ts:=`date -u "+%a %b %e %T %Z %Y"`}" "$1" "${SHLOG_INDENT:=}" "$2"
	done
}

# 1:Level Text; 2:Line Prefix
ShLogPipe () {
	local ts= line= writer=

	# Send each line of input to each writer function (defaults ShLog2File and ShLog2StdOut).
	while IFS= read -r line; do
		for writer in ${SHLOG_WRITERS:=ShLog2File ShLog2StdOut}; do
			$writer "${ts:=`date -u "+%a %b %e %T %Z %Y"`}" "$1" "${SHLOG_INDENT:=}" "${2:-}$line"
		done
	done
}

# 1:Timestamp; 2:Level Text; 3:Prefix; 4:Log Message
ShLog2File() {
	# Rotate log file if we've exceeded $SHLOG_SIZE.
	if [ -f "${SHLOG_FILE:=~/${BASH_SOURCE##*/}.log}" ]; then
		if [ `du -k $SHLOG_FILE | cut -f1` -ge ${SHLOG_SIZE:=1024} ]; then
			if [ -f "$SHLOG_FILE.0" ]; then
				i=${SHLOG_COUNT:=10}
				while [ $i -gt 1 ]; do
					i=$(( $i - 1 ))
					j=$(( $i - 1 ))
					if [ -f "$SHLOG_FILE.$j" ]; then
						mv -f $SHLOG_FILE.$j $SHLOG_FILE.$i || true
					fi
				done
			fi

			mv -f $SHLOG_FILE $SHLOG_FILE.0 || true
			eval "exec ${SHLOG_FD:=9}>>${SHLOG_FILE}"
		fi
	fi

	# Open the log file
	if [ ! -e /proc/$$/fd/${SHLOG_FD:=9} ]; then
		eval "exec ${SHLOG_FD}>>${SHLOG_FILE}"
	fi

	echo -e "$4" | sed -e "s/^/$1	${HOSTNAME:=`hostname`}	${USER:=`id -un`}	$$	$2	$3/" >&$SHLOG_FD
}

# 1:Timestamp; 2:Level Text; 3:Prefix; 4:Log Message
ShLog2StdOut() {
	echo -e "$4" | sed -e "s/^/$3/"
}

# 1:Timestamp; 2:Level Text; 3:Prefix; 4:Log Message
ShLog2StdErr() {
	echo -e "$4" | sed -e "s/^/$3/" >&2
}

ShLogLevel () {
	local level="$(echo "${1:-INFO}" | tr '[:lower:]' '[:upper:]')"

	case "$level" in
		ERROR|-3)		SHLOG_LEVEL=-3;;
		WARNING|-2)		SHLOG_LEVEL=-2;;
		NOTICE|-1)		SHLOG_LEVEL=-1;;
		INFO|0)			SHLOG_LEVEL=0;;
		CONFIG|1)		SHLOG_LEVEL=1;;
		DEBUG|2)		SHLOG_LEVEL=2;;
		FINE|3)			SHLOG_LEVEL=3;;
		FINER|4)		SHLOG_LEVEL=4;;
		FINEST|5|ALL)	SHLOG_LEVEL=5;;
		*)	ShLogWarning "Ignoring unrecognised logging level $level";;
	esac
	ShLog "LOGGING" "Logging level ${level}"
}

ShLogError () {
	if [ ${SHLOG_LEVEL:-0} -ge -3 ]; then
		if [ "$*" = "--pipe" ]; then
			ShLogPipe "ERROR" "ERROR: " >&2
		else
			ShLog "ERROR" "ERROR: $*" >&2
		fi
	fi
}

ShLogWarning () {
	if [ ${SHLOG_LEVEL:-0} -ge -2 ]; then
		if [ "$*" = "--pipe" ]; then
			ShLogPipe "WARNING" "WARNING: " >&2
		else
			ShLog "WARNING" "WARNING: $*" >&2
		fi
	fi
}

ShLogNotice () {
	if [ ${SHLOG_LEVEL:-0} -ge -1 ]; then
		if [ "$*" = "--pipe" ]; then
			ShLogPipe "NOTICE" "NOTICE: "
		else
			ShLog "NOTICE" "NOTICE: $*"
		fi
	fi
}

ShLogInfo () {
	if [ ${SHLOG_LEVEL:-0} -ge 0 ]; then
		if [ "$*" = "--pipe" ]; then
			ShLogPipe "INFO"
		else
			ShLog "INFO" "$*"
		fi
	fi
}

ShLogConfig () {
	if [ ${SHLOG_LEVEL:-0} -ge 1 ]; then
		if [ "$*" = "--pipe" ]; then
			ShLogPipe "CONFIG"
		else
			ShLog "CONFIG" "$*"
		fi
	fi
}

ShLogDebug () {
	if [ ${SHLOG_LEVEL:-0} -ge 2 ]; then
		if [ "$*" = "--pipe" ]; then
			ShLogPipe "DEBUG"
		else
			ShLog "DEBUG" "$*"
		fi
	fi
}

ShLogFine () {
	if [ ${SHLOG_LEVEL:-0} -ge 3 ]; then
		if [ "$*" = "--pipe" ]; then
			ShLogPipe "FINE"
		else
			ShLog "FINE" "$*"
		fi
	fi
}

ShLogEnter () {
	if [ ${SHLOG_LEVEL:-0} -ge 4 ]; then
		if [ "$*" = "--pipe" ]; then
			ShLogPipe "ENTER" "->"
		else
			ShLog "ENTER" "->$*"
		fi
		SHLOG_INDENT="${SHLOG_INDENT:-}  "
	fi
}

ShLogLeave () {
	if [ ${SHLOG_LEVEL:-0} -ge 4 ]; then
		SHLOG_INDENT="${SHLOG_INDENT#*  }"
		if [ "$*" = "--pipe" ]; then
			ShLogPipe "LEAVE" "<-"
		else
			ShLog "LEAVE" "<-$*"
		fi
	fi
}

ShLogFiner () {
	if [ ${SHLOG_LEVEL:-0} -ge 4 ]; then
		if [ "$*" = "--pipe" ]; then
			ShLogPipe "FINER"
		else
			ShLog "FINER" "$*"
		fi
	fi
}

ShLogFinest () {
	if [ ${SHLOG_LEVEL:-0} -ge 5 ]; then
		if [ "$*" = "--pipe" ]; then
			ShLogPipe "FINEST"
		else
			ShLog "FINEST" "$*"
		fi
	fi
}
