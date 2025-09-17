#!/bin/bash

# Remove log from previous execution
rm -f ./results.log

# Initialize errors list
errors=""

# Iterate for all assembly files
for file in ./S/*.S; do
  filename=$(basename "$file" .S)

  # Run test and compare with reference model
  echo "********* RUNNING TEST $filename *********" | tee -a ./results.log
  make batch_ref TEST_NAME=$filename | tee -a ./results.log

  # Check if test has failed
  if [[ "$(tail -n 1 ./results.log)" != "Register-files match" ]]; then
    # If test has failed, print message and add to list of errors
    echo "TEST $filename FAILED!"
    errors+="\nTEST $filename FAILED!"
  fi
done 

# Check if any tests have failed
echo ""
echo "-----------"
if [[ $errors = "" ]]; then
  echo "No errors"
else
  # Print names of failed tests
  echo -e "$errors"
fi
echo "-----------"

# Delete log of tests
rm -f ./results.log
