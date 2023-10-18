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
}

cleanup(){
    for pid in "${pids[@]}"; do
        kill -9 "$pid"
        echo "Killed process: $pid"
    done
    kill -9 $(ps aux | grep ifstat | awk '{print $2}')
    exit $?
}

process_level_metrics() {
    echo -n "$total_time," >> process_metrics.csv
    for ((i=0; i<6; i++)); do
        pid=${pids[$i]}
        # exlude ifstat_pid
        if [[ $i -eq 5 ]]; then
            ps -aux | grep -E "\s$pid\s" | awk '{print $3, ",", $4}' >> process_metrics.csv
        else
            echo -n "$(ps -aux | grep -E "\s$pid\s" | awk '{print $3, ",", $4, ","}')" >> process_metrics.csv
        fi
    done
}


system_level_metrics(){
    echo -n "$total_time, " >> system_metrics.csv
    echo -n $(ifstat | grep ens33 |awk '{print $7}') >> system_metrics.csv
    echo -n "," >> system_metrics.csv
    echo -n $(ifstat | grep ens33 |awk '{print $9}') >> system_metrics.csv
    echo -n "," >> system_metrics.csv
    echo -n $(iostat | grep sda | awk '{print $4}') >> system_metrics.csv
    echo -n "," >> system_metrics.csv
    echo $(df -h -m /dev/mapper/centos-root | awk '{print $4}'| tail -1) >> system_metrics.csv
}

main(){
    echo "Time,RX Data Rate,TX Data Rate,Disk Writes,Disk Capacity"  >> system_metrics.csv
    echo "Time,APM 1 CPU,APM 1 Memory,APM 2 CPU,APM 2 Memory,APM 3 CPU,APM 3 Memory,APM 4 CPU,APM 4 Memory,APM 5 CPU,APM 5 Memory,APM 6 CPU,APM 6 Memory" >> process_metrics.csv
    #trap ctrl-c and call cleanup function
    trap cleanup SIGINT
    #get IP address from user
    read -p "Please enter the IP address: " IP
    start_processes "$IP"
    SECONDS=0;
    while true; do
        sleep 5;
        echo "Skipping 5s"
		total_time=$SECONDS
		if [[ $total_time -ge 905 ]]; then
			cleanup
		fi
        #make and call process metrics
        process_level_metrics
        #make and call system metrics
        system_level_metrics
    done
}

main
