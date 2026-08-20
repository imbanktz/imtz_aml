#!/bin/bash
# script/rtgs_cron.sh
# Cronjob script for RTGS processing - calls the Rails process_rtgs_batch method

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(dirname "$SCRIPT_DIR")"

# Configuration
RAILS_ENV=${RAILS_ENV:-"production"}
LIMIT=${1:-"all"}  # Default to all files, or pass a number as first argument
LOG_DIR="$APP_DIR/log"
LOG_FILE="$LOG_DIR/rtgs_cron_$(date +%Y%m%d).log"
PID_FILE="$APP_DIR/tmp/pids/rtgs_cron.pid"

# Create directories if they don't exist
mkdir -p "$LOG_DIR"
mkdir -p "$APP_DIR/tmp/pids"

# Colors for output (only if terminal)
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

# Logging function
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_success() {
    log_message "✅ $1"
}

log_error() {
    log_message "❌ $1"
}

log_warning() {
    log_message "⚠️ $1"
}

log_info() {
    log_message "ℹ️ $1"
}

# Function to check if already running
check_running() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            log_warning "Process already running with PID $PID"
            return 0
        else
            log_info "Removing stale PID file"
            rm -f "$PID_FILE"
        fi
    fi
    return 1
}

# Function to create PID file
create_pid() {
    echo $$ > "$PID_FILE"
}

# Function to remove PID file
remove_pid() {
    rm -f "$PID_FILE"
}

# Function to run Rails command
run_rails_command() {
    cd "$APP_DIR"
    bundle exec rails runner "$1"
}

# Function to process RTGS files
process_rtgs_files() {
    log_info "Starting RTGS processing..."
    
    # Build the limit parameter
    local limit_param=""
    if [ "$LIMIT" != "all" ] && [ "$LIMIT" -gt 0 ] 2>/dev/null; then
        limit_param=", $LIMIT"
        log_info "Processing limit: $LIMIT files"
    else
        log_info "Processing all files"
    fi
    
    # Run the Rails command using process_rtgs_batch
    local rails_command="
        # Load console helpers
        load 'config/initializers/console_helpers.rb' if File.exist?('config/initializers/console_helpers.rb')
        
        # Check if process_rtgs_batch exists
        if defined?(process_rtgs_batch)
            puts '📊 Processing RTGS files...'
            result = process_rtgs_batch($LIMIT)
            puts \"Result: \#{result.inspect}\"
            result
        else
            # Fallback: use the job directly
            puts '⚠️ process_rtgs_batch not found, using job directly'
            remote_path = '/amlock/Tanzania/RMS/mxt_to_mt/rtgs_source_only'
            remote_service = RemoteFileService.new(
                host: AMLOCK_SERVER_IP,
                username: AMLOCK_USER_NAME,
                password: AMLOCK_PASSWORD
            )
            
            all_files = remote_service.list_rtgs_files(remote_path) || []
            files_to_process = $LIMIT ? all_files.first($LIMIT) : all_files
            
            puts \"Processing \#{files_to_process.count} files\"
            
            processed = 0
            failed = 0
            skipped = 0
            
            files_to_process.each do |file|
                file_name = file.is_a?(String) ? file : file.name
                puts \"\n📄 \#{file_name}\"
                
                job = ProcessRtgsWithManualParserJob.new
                result = job.send(:process_file, remote_service, file, remote_path)
                
                case result
                when :processed
                    processed += 1
                when :skipped
                    skipped += 1
                else
                    failed += 1
                end
            end
            
            puts \"\n📊 Summary: Processed: \#{processed}, Failed: \#{failed}, Skipped: \#{skipped}\"
            { processed: processed, failed: failed, skipped: skipped }
        end
    "
    
    # Replace $LIMIT in the command
    rails_command="${rails_command//\$LIMIT/$LIMIT}"
    
    # Run the command
    run_rails_command "$rails_command"
    
    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        log_success "RTGS processing completed successfully"
    else
        log_error "RTGS processing failed with exit code: $exit_code"
    fi
    
    return $exit_code
}

# Function to check status
check_status() {
    log_info "Checking RTGS status..."
    
    local rails_command="
        puts '📊 RTGS Status:'
        puts \"  Total: \#{Transaction.count}\"
        puts \"  Pending: \#{Transaction.where(screening_status: 'pending').count}\"
        puts \"  Processing: \#{Transaction.where(screening_status: 'processing').count}\"
        puts \"  Completed: \#{Transaction.where(screening_status: 'completed').count}\"
        puts \"  Failed: \#{Transaction.where(screening_status: 'failed').count}\"
        
        if Redis.current.get('rtgs_processor:last_run')
            puts \"  Last run: \#{Redis.current.get('rtgs_processor:last_run')}\"
        end
    "
    
    run_rails_command "$rails_command"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  process [limit]  - Process RTGS files (default: all files)"
    echo "  status           - Check processing status"
    echo "  help             - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 process 10    - Process 10 files"
    echo "  $0 process all   - Process all files"
    echo "  $0 status        - Check status"
    echo ""
}

# Main function
main() {
    # Check if already running
    if check_running; then
        exit 0
    fi
    
    # Create PID file
    create_pid
    
    # Trap exit to remove PID file
    trap remove_pid EXIT
    
    # Parse arguments
    local action="process"
    local limit="all"
    
    if [ -n "$1" ]; then
        if [ "$1" == "status" ]; then
            action="status"
        elif [ "$1" == "help" ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
            show_usage
            exit 0
        elif [ "$1" == "process" ]; then
            action="process"
            if [ -n "$2" ]; then
                limit="$2"
            fi
        else
            # If first arg is a number, treat it as limit for process
            if [ "$1" -gt 0 ] 2>/dev/null; then
                limit="$1"
            else
                echo "Unknown option: $1"
                show_usage
                exit 1
            fi
        fi
    fi
    
    # Set LIMIT for the script
    LIMIT="$limit"
    
    # Execute action
    case "$action" in
        status)
            check_status
            ;;
        process)
            log_info "="*60
            log_info "🚀 RTGS Cron Job Started"
            log_info "Limit: $LIMIT"
            log_info "Environment: $RAILS_ENV"
            log_info "="*60
            
            process_rtgs_files
            
            local exit_code=$?
            
            log_info "="*60
            log_info "🏁 RTGS Cron Job Completed"
            log_info "Exit Code: $exit_code"
            log_info "="*60
            
            exit $exit_code
            ;;
    esac
}

# Run main function
main "$@"
