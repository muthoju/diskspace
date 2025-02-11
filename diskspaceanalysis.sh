#!/bin/bash

# Define thresholds
CPU_THRESHOLD=80
MEM_THRESHOLD=80
DISK_THRESHOLD=90
LOAD_THRESHOLD=5.0

# Log file
LOG_FILE="/var/log/server_health.log"

# Get current timestamp
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# Get system metrics
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')
MEM_USAGE=$(free | awk '/Mem:/ {printf "%.2f", $3/$2 * 100}')
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
LOAD_AVG=$(uptime | awk -F 'load average:' '{print $2}' | cut -d, -f1 | xargs)

# Function to log and alert if threshold is exceeded
check_threshold() {
    local metric_name=$1
    local metric_value=$2
    local threshold=$3
    
    if (( $(echo "$metric_value > $threshold" | bc -l) )); then
        echo "$TIMESTAMP - ALERT: $metric_name usage is high: $metric_value%" | tee -a $LOG_FILE
    else
        echo "$TIMESTAMP - INFO: $metric_name usage is normal: $metric_value%" | tee -a $LOG_FILE
    fi
}

# Check CPU usage
check_threshold "CPU" "$CPU_USAGE" "$CPU_THRESHOLD"

# Check Memory usage
check_threshold "Memory" "$MEM_USAGE" "$MEM_THRESHOLD"

# Check Disk usage
check_threshold "Disk" "$DISK_USAGE" "$DISK_THRESHOLD"

# Check Load Average
if (( $(echo "$LOAD_AVG > $LOAD_THRESHOLD" | bc -l) )); then
    echo "$TIMESTAMP - ALERT: Load Average is high: $LOAD_AVG" | tee -a $LOG_FILE
else
    echo "$TIMESTAMP - INFO: Load Average is normal: $LOAD_AVG" | tee -a $LOG_FILE
fi

# Check top 5 consuming processes
echo "$TIMESTAMP - Top 5 Processes by CPU & Memory usage:" | tee -a $LOG_FILE
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -6 | tee -a $LOG_FILE

echo "Server health check completed." | tee -a $LOG_FILE
