#!/bin/bash

testCount=1
goodResult=0
./attack 'fileNot123Existing%$#@!%^&*()P{}>L:"L":?<>?'
res=$?
if [ $res == 1 ]; then
        goodResult=$((goodResult+1))
else
        echo "Error: Test filename not existing failed: output $res instead of 1"
fi
for filename in tests/*.0; do
        ./attack $filename
        res=$?
        testCount=$((testCount+1))
        if [ $res == 0 ]; then
                goodResult=$((goodResult+1))
        else
                echo "ERROR: Test $filename failed: output code $res instead of 0"
        fi
done

for filename in tests/*.1; do
        ./attack $filename
        res=$?
        testCount=$((testCount+1))
        if [ $res == 1 ]; then
                goodResult=$((goodResult+1))
        else
                echo "ERROR: Test $filename failed: output code $res instead of 1"
        fi
done

echo "Out of all $testCount tests, $goodResult have been passed"
