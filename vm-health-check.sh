#!/bin/bash

# VM Health Check Script
# Monitors CPU, Memory, and Disk usage
# Declares VM healthy if all metrics are below 60%

echo "========================================="
echo "     VM Health Check Analysis"
echo "========================================="
echo "Timestamp: $(date)"
echo

# Function to get CPU usage percentage
get_cpu_usage() {
    # Get CPU usage using top command (1 second sample)
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
    
    # Alternative method using vmstat if top doesn't work as expected
    if [ -z "$cpu_usage" ] || [ "$cpu_usage" = "0.0" ]; then
        # Using vmstat for more reliable CPU measurement
        cpu_idle=$(vmstat 1 2 | tail -1 | awk '{print $15}')
        cpu_usage=$(echo "100 - $cpu_idle" | bc -l)
    fi
    
    # Remove decimal point and round to integer
    cpu_usage=$(echo "$cpu_usage" | cut -d. -f1)
    echo "$cpu_usage"
}

# Function to get Memory usage percentage
get_memory_usage() {
    memory_usage=$(free | grep Mem | awk '{printf "%.0f", ($3/$2) * 100.0}')
    echo "$memory_usage"
}

# Function to get Disk usage percentage
get_disk_usage() {
    # Get disk usage for root partition
    disk_usage=$(df / | grep -vE '^Filesystem|tmpfs|cdrom' | awk '{print $5}' | sed 's/%//')
    echo "$disk_usage"
}

# Function to check if bc command is available
check_bc() {
    if ! command -v bc &> /dev/null; then
        echo "Warning: 'bc' command not found. Installing basic calculator functionality..."
        # For systems without bc, we'll use awk for calculations
        return 1
    fi
    return 0
}

# Main health check function
perform_health_check() {
    echo "Collecting system metrics..."
    echo

    # Get system metrics
    cpu_percent=$(get_cpu_usage)
    memory_percent=$(get_memory_usage)
    disk_percent=$(get_disk_usage)

    # Display current usage
    echo "Current System Usage:"
    echo "---------------------"
    echo "CPU Usage:    ${cpu_percent}%"
    echo "Memory Usage: ${memory_percent}%"
    echo "Disk Usage:   ${disk_percent}%"
    echo

    # Set threshold
    threshold=60

    # Check each metric against threshold
    echo "Health Analysis (Threshold: ${threshold}%):"
    echo "----------------------------------------"

    # Initialize health status
    vm_healthy=true
    issues_found=""

    # Check CPU
    if [ "$cpu_percent" -gt "$threshold" ]; then
        echo "❌ CPU Usage: ${cpu_percent}% (CRITICAL - Above ${threshold}%)"
        vm_healthy=false
        issues_found="${issues_found}CPU(${cpu_percent}%) "
    else
        echo "✅ CPU Usage: ${cpu_percent}% (OK - Below ${threshold}%)"
    fi

    # Check Memory
    if [ "$memory_percent" -gt "$threshold" ]; then
        echo "❌ Memory Usage: ${memory_percent}% (CRITICAL - Above ${threshold}%)"
        vm_healthy=false
        issues_found="${issues_found}Memory(${memory_percent}%) "
    else
        echo "✅ Memory Usage: ${memory_percent}% (OK - Below ${threshold}%)"
    fi

    # Check Disk
    if [ "$disk_percent" -gt "$threshold" ]; then
        echo "❌ Disk Usage: ${disk_percent}% (CRITICAL - Above ${threshold}%)"
        vm_healthy=false
        issues_found="${issues_found}Disk(${disk_percent}%) "
    else
        echo "✅ Disk Usage: ${disk_percent}% (OK - Below ${threshold}%)"
    fi

    echo
    echo "========================================="
    
    # Final health status
    if [ "$vm_healthy" = true ]; then
        echo "🟢 VM HEALTH STATUS: HEALTHY"
        echo "All system resources are within acceptable limits."
        exit_code=0
    else
        echo "🔴 VM HEALTH STATUS: NOT HEALTHY"
        echo "Issues detected with: $issues_found"
        echo "Immediate attention required!"
        exit_code=1
    fi
    
    echo "========================================="
    
    return $exit_code
}

# Function to show detailed system information
show_detailed_info() {
    echo
    echo "Detailed System Information:"
    echo "=============================="
    
    echo
    echo "CPU Information:"
    echo "----------------"
    lscpu | grep -E "Model name|CPU\(s\)|Thread|Core"
    
    echo
    echo "Memory Information:"
    echo "-------------------"
    free -h
    
    echo
    echo "Disk Information:"
    echo "-----------------"
    df -h | grep -E "Filesystem|/dev/"
    
    echo
    echo "System Load:"
    echo "------------"
    uptime
}

# Function to log results
log_results() {
    log_file="vm_health_$(date +%Y%m%d_%H%M%S).log"
    echo "Logging results to: $log_file"
    
    {
        echo "VM Health Check - $(date)"
        echo "CPU: ${cpu_percent}%, Memory: ${memory_percent}%, Disk: ${disk_percent}%"
        if [ "$vm_healthy" = true ]; then
            echo "Status: HEALTHY"
        else
            echo "Status: NOT HEALTHY - Issues: $issues_found"
        fi
    } > "$log_file"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--detailed)
            DETAILED=true
            shift
            ;;
        -l|--log)
            LOG_RESULTS=true
            shift
            ;;
        -h|--help)
            echo "VM Health Check Script"
            echo "Usage: $0 [OPTIONS]"
            echo
            echo "OPTIONS:"
            echo "  -d, --detailed    Show detailed system information"
            echo "  -l, --log         Log results to file"
            echo "  -h, --help        Show this help message"
            echo
            echo "The script checks CPU, Memory, and Disk usage."
            echo "VM is considered healthy if ALL metrics are below 60%."
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information."
            exit 1
            ;;
    esac
done

# Check if running as root (optional warning)
if [ "$EUID" -ne 0 ]; then
    echo "Note: Running as non-root user. Some metrics might be limited."
    echo
fi

# Main execution
perform_health_check
exit_code=$?

# Store values for logging
cpu_percent=$(get_cpu_usage)
memory_percent=$(get_memory_usage)
disk_percent=$(get_disk_usage)

# Show detailed information if requested
if [ "$DETAILED" = true ]; then
    show_detailed_info
fi

# Log results if requested
if [ "$LOG_RESULTS" = true ]; then
    log_results
fi

exit $exit_code