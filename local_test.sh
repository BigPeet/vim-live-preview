#!/usr/bin/env bash

SCRIPT_NAME=$0
SCRIPT_DIR=$(dirname $SCRIPT_NAME)
PLUGIN_DIR=$SCRIPT_DIR

FAILED=()
SUCCEEDED=()

if [[ -z $1 ]]; then
  TEST=$(ls $PLUGIN_DIR/test/test_*.vader)
else
  TEST=$1
fi

start=$(date +%s)

for test_file in ${TEST}; do
  echo -en "Running test: $test_file ...\t"
  vader_out=$(vim -N -c "Vader! ${PLUGIN_DIR}/${test_file}" 2>&1 > /dev/null)
  if [ $? -ne 0 ]; then
    #echo "Failed test: $test_file"
    echo "FAILED"
    FAILED+=($test_file)
    echo "Details:"
    echo "$vader_out"
  else
    #echo "Succeeded test: $test_file"
    echo "SUCCEEDED"
    SUCCEEDED+=($test_file)
  fi
done

end=$(date +%s)

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

echo "Time elapsed: $((end-start)) seconds"

if [ ${#FAILED[@]} -gt 0 ]; then
  echo -e "\033[0;31m[TEST RUN FAILED]\033[0m"
  exit 1
else
  echo -e "\033[0;32m[TEST RUN SUCCEEDED]\033[0m"
  exit 0
fi

