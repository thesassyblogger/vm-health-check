#!/bin/bash

# Simple VM Health Check Script
# Checks CPU, Memory, and Disk usage
# Prints "Healthy" if all are below 60%, else "Not Healthy"
# Use "explain" argument for detailed breakdown

# Function to get CPU usage percentage
get_cpu_usage() {
    # Get CPU usage using top command
    cpu_idle=$(vmstat 1 2 | tail -1 | awk '{print $15}')
    cpu_usage=$(echo "100 - $cpu_idle" | bc -l 2>/dev/null || echo "100 - $cpu_idle" | awk '{print $1}')
    # Convert to integer
    echo "$cpu_usage" | cut -d. -f1
}

# Function to get Memory usage percentage
get_memory_usage() {
    free | grep Mem | awk '{printf "%.0f", ($3/$2) * 100.0}'
}

# Function to get Disk usage percentage for root partition
get_disk_usage() {
    df / | grep -vE '^Filesystem|tmpfs|cdrom' | awk '{print $5}' | sed 's/%//'
}

# Check if explain argument is provided
explain_mode=false
if [ "$1" = "explain" ]; then
    explain_mode=true
fi

# Get system metrics
cpu_percent=$(get_cpu_usage)
memory_percent=$(get_memory_usage)
disk_percent=$(get_disk_usage)

# Set threshold
threshold=60

# If explain mode, show detailed breakdown
if [ "$explain_mode" = true ]; then
    echo "Ubuntu VM Health Check - Detailed Analysis"
    echo "=========================================="
    echo "Current System Usage:"
    echo "  CPU Usage:    ${cpu_percent}%"
    echo "  Memory Usage: ${memory_percent}%"
    echo "  Disk Usage:   ${disk_percent}%"
    echo ""
    echo "Health Threshold: ${threshold}%"
    echo ""
    echo "Individual Component Status:"
    
    # Check CPU
    if [ "$cpu_percent" -lt "$threshold" ]; then
        echo "  ✓ CPU: ${cpu_percent}% - HEALTHY (below ${threshold}%)"
    else
        echo "  ✗ CPU: ${cpu_percent}% - UNHEALTHY (above ${threshold}%)"
    fi
    
    # Check Memory
    if [ "$memory_percent" -lt "$threshold" ]; then
        echo "  ✓ Memory: ${memory_percent}% - HEALTHY (below ${threshold}%)"
    else
        echo "  ✗ Memory: ${memory_percent}% - UNHEALTHY (above ${threshold}%)"
    fi
    
    # Check Disk
    if [ "$disk_percent" -lt "$threshold" ]; then
        echo "  ✓ Disk: ${disk_percent}% - HEALTHY (below ${threshold}%)"
    else
        echo "  ✗ Disk: ${disk_percent}% - UNHEALTHY (above ${threshold}%)"
    fi
    
    echo ""
    echo "Overall Health Status:"
fi

# Check if all metrics are below threshold
if [ "$cpu_percent" -lt "$threshold" ] && [ "$memory_percent" -lt "$threshold" ] && [ "$disk_percent" -lt "$threshold" ]; then
    if [ "$explain_mode" = true ]; then
        echo "  ✓ HEALTHY - All system resources are within acceptable limits"
        echo ""
        echo "Explanation: The Ubuntu VM is considered healthy because all three"
        echo "critical resources (CPU, Memory, and Disk) are operating below the"
        echo "60% threshold, indicating sufficient available capacity."
    else
        echo "Healthy"
    fi
else
    if [ "$explain_mode" = true ]; then
        echo "  ✗ NOT HEALTHY - One or more system resources exceed safe limits"
        echo ""
        echo "Explanation: The Ubuntu VM is considered unhealthy because at least"
        echo "one critical resource (CPU, Memory, or Disk) is operating at or above"
        echo "the 60% threshold. This may lead to performance degradation or system"
        echo "instability. Consider investigating high resource usage processes or"
        echo "scaling the VM resources."
    else
        echo "Not Healthy"
    fi
fi