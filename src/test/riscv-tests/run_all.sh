#!/bin/bash

rm -f ./results.log
for file in ./S/*.S; do
  filename=$(basename "$file" .S)
  echo "********* RUNNING TEST $filename *********" | tee -a ./results.log
  make batch SOURCE_FILE_NAME="$filename" | tee -a ./results.log
done 

errors=$(grep -n "RF content differs" ./results.log)
echo ""
echo "-----------"
if [[ -z $errors ]]; then
  echo "No errors"
else
  echo "$errors"
fi
echo "-----------"
rm -f ./results.log
