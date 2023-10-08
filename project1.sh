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

main(){
    #trap ctrl-c and call cleanup function
    trap cleanup SIGINT
    #get IP address from user
    read -p "Please enter the IP address: " IP
    start_processes "$IP"
    SECONDS = 0;
    while true; do
        sleep 5;
        echo "Skipping 5s"
		total_time=$SECONDS
		if [[ $total_time -ge 900 ]]; then
			cleanup
		fi
		#make and call process metrics
        #make and call system metrics
    done
}