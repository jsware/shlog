#!/usr/bin/env bash
###
# @file all.sh Run all the scripts in this script's directory.
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

# Check for help option...
if [ "$*" = "?" -o "$*" = "-?" -o "$*" = "/?" -o "$*" = "-h" -o "$*" = "--help" ]; then
	cat << :END
Usage: ${0##*/} [Options] [ScriptPatterns...]
Run the scripts, counting the failures (default is *.sh scripts).

The options provided will be passed through to the executed scripts.
Options:
  -v Verbose.
  -x Debug.

Returns the number scripts returning a non-zero exit code.
:END
	exit 0
fi

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

	# Capture the option so it can be passed through to each script.
	OPTS="${OPTS:-}${OPTS:+ }-${OPT}${OPTARG:+ }${OPTARG:-}"
done
shift $(( $OPTIND - 1 ))

if [ $# -ne 0 ]; then
	SCRIPT_PATTERNS="$*"	# Pick up all the script patterns provided.
fi

# Set defaults; echo out parameters if verbose on...
echo "Script Patterns = '${SCRIPT_PATTERNS:=*.sh}'." >&3
echo "Script Options  = '${OPTS:=}'." >&3

# Run the test scripts...
failed=0
total=0
for scripts in "$SCRIPT_PATTERNS"; do
	# Process each script pattern (allow expansion into file names).
	for script in ${0%/*}/$scripts; do
		# Process each script, skipping this script.
		if [ "$script" = "$0" ]; then
			echo "Skipping script '$script'." >&3
		else
			total=$(( $total + 1 ))

			# Only run if readable and executable.
			if [ -r "$script" -a -x "$script" ]; then
				echo "Running script '$script $OPTS':"
				rc=0
				$script $OPTS || rc=$?
				if [ $rc -ne 0 ]; then
					echo "ERROR: Script '$script' failed (RC $rc)." >&2
					failed=$(( $failed + 1 ))
				else
					echo "Script '$script' completed OK (RC $rc)."
				fi
			else
				echo "ERROR: Script '$script' not readable/executable." >&2
				ls -l "$script" >&3 2>&1 || true
				failed=$(( $failed + 1 ))
			fi
		fi
	done
done


#
# Check if we counted any failures.
#
if [ $failed -ne 0 ]; then
	echo "ERROR: $failed script(s) out of $total failed (only $(( $total - $failed)) worked)." >&2
else
	echo "SUCCESS: All $total script(s) worked ($failed failed)."
fi
exit $failed
