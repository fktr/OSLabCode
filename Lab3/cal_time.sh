#!/bin/bash

start=$(date "+%s")
./process
end=$(date "+%s")
time=$((end-start))
echo "time used:$time seconds"
