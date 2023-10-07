#!/bin/bash

pids=()
start_processes() {
    processes=("APM1" "APM2" "APM3" "APM4" "APM5" "APM6")
    for process in "${processes[@]}"; do
        ./"$process" "$1" &
        pid=$!
        pids+=("$pid")
        echo "Started $process: $pid"
    done

    ifstat -a -d 1
    ifstat_pid=$!
    pids+=("$ifstat_pid")
}


cleanup(){
    for pid in "${pids[@]}"; do
        kill -9 "$pid"
        echo "Killed process: $pid"
    done
    exit $?
}