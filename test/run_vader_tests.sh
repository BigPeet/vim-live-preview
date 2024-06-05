#!/usr/bin/env bash

# This script expects that vader plugin is installed and
# vim config is setup up approriately to run the tests.

SCRIPT_NAME=$0
SCRIPT_DIR=$(dirname $SCRIPT_NAME)
PLUGIN_DIR=$(dirname $SCRIPT_DIR)

function print_vader_output() {
  if [ $VERBOSE -eq 0 ]; then
    return
  fi
  echo "Details:"
  echo "$1" | sed -e '1,/Starting Vader:/d'
}

VERBOSE=0

# option parsing
while [[ $# -gt 0 ]]; do
  case $1 in
    -v | --verbose)
      VERBOSE=1
      shift
      ;;
    -* | --*)
      echo "Invalid option: $1"
      exit 1
      ;;
    *) # positional argument
      break
      ;;
  esac
done

FAILED=()
SUCCEEDED=()

if [[ -z $1 ]]; then
  TEST=$(ls $PLUGIN_DIR/test/test_*.vader)
else
  TEST=$1
fi

echo "Tests to run: $TEST"

START=$(date +%s)

for test_file in ${TEST}; do
  echo "Running test: $test_file"
  echo -en "Running test: $test_file ...\t"
  vader_out=$(vim -N -c "Vader! ${test_file}" 2>&1 > /dev/null)
  if [ $? -ne 0 ]; then
    FAILED+=($test_file)
    echo "FAILED"
    print_vader_output "$vader_out"
  else
    SUCCEEDED+=($test_file)
    echo "SUCCEEDED"
    print_vader_output "$vader_out"
  fi
done

END=$(date +%s)

echo
echo "SUMMARY:"
echo "Succeeded tests:"
for test_file in ${SUCCEEDED[@]}; do
  echo "  $test_file"
done
echo "Failed tests:"
for (( i = 0; i < ${#FAILED[@]}; i++ )); do
  echo "  ${FAILED[$i]}"
done
echo

echo "Time elapsed: $((END-START)) seconds"

if [ ${#FAILED[@]} -gt 0 ]; then
  echo -e "\033[0;31m[TEST RUN FAILED]\033[0m"
  exit 1
else
  echo -e "\033[0;32m[TEST RUN SUCCEEDED]\033[0m"
  exit 0
fi

