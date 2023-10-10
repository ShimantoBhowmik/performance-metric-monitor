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

system_level_metrics(){
    RX_rate= `ifstat | grep ens33 |awk '{print $7}'`
    TX_rate= `ifstat | grep ens33 |awk '{print $9}'`
    Disk_writes= `iostat | grep sda | awk '{print $4}'`
    Disk_available= `df -h -m /dev/mapper/centos-root | awk '{print $4}'| tail -1`
    echo "$total_time,$RX_rate,$TX_rate,$Disk_writes,$Disk_available" >> system_metrics.csv
}

main(){
    echo "Time,RX Data Rate,TX Data Rate,Disk Writes,Disk Capacity"  >> system_metrics.csv
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
		if [[ $total_time -ge 900 ]]; then
			cleanup
		fi
        #make and call system metrics
        system_level_metrics
		#make and call process metrics
        
    done
}

main