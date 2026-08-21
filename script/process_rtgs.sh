#!/bin/bash
# Author: Abdillah Muna | abdillah.muna@imbank.co.tz | abdimuna1@gmail.com
# Date: 20, August 2026
# script/process_rtgs.sh
# Author: Abdillah Muna
# RTGS Processing Script - Downloads and processes RTGS files via Docker
# Supports multiple source directories: TT_INCOMING, TT_OUTGOING, RTGS_INCOMING, RTGS_OUTGOING

# #################### USAGE ####################
# # Process all files from ALL directories (today and yesterday)
# ./process_rtgs.sh process all

# # Process 5 files from ALL directories
# ./process_rtgs.sh process 5

# # Process from specific source (today)
# ./process_rtgs.sh source TT_INCOMING 5

# # Process from specific source with custom date
# ./process_rtgs.sh source TT_INCOMING 2026-08-20 5

# # Process RTGS_OUTGOING with compact date format
# ./process_rtgs.sh source RTGS_OUTGOING 20260821 all

# # List available directories
# ./process_rtgs.sh list

# # Check status
# ./process_rtgs.sh status

# # Custom lookback days
# export LOOKBACK_DAYS=3
# ./process_rtgs.sh process 10
# ##################################################
#
# Path formats:
#   RTGS_OUTGOING: /amlock/Tanzania/RMS/input_rtgs_via_swift/MX_OUT/YYYYMMDD
#   RTGS_INCOMING: /amlock/Tanzania/RMS/input/bkp/in/YYYY-MM-DD
#   TT_INCOMING:   /amlock/Tanzania/RMS/input/bkp/in/YYYY-MM-DD
#   TT_OUTGOING:   /amlock/Tanzania/RMS/input/bkp/out/YYYY-MM-DD

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
LIMIT=${1:-"all"}
SERVICE_NAME=${SERVICE_NAME:-"imtz_aml-web"}

# Get current date in different formats
TODAY_YYYYMMDD=$(date +%Y%m%d)
TODAY_YYYY_MM_DD=$(date +%Y-%m-%d)
YESTERDAY_YYYY_MM_DD=$(date -d "yesterday" +%Y-%m-%d 2>/dev/null || date -v-1d +%Y-%m-%d)

# Base paths
BASE_PATH="/amlock/Tanzania/RMS"

# Build paths with dynamic dates
# You can override these with environment variables
RTGS_OUTGOING_PATH="${RTGS_OUTGOING_PATH:-$BASE_PATH/input_rtgs_via_swift/MX_OUT/$TODAY_YYYYMMDD}"
RTGS_INCOMING_PATH="${RTGS_INCOMING_PATH:-$BASE_PATH/input/bkp/in/$TODAY_YYYY_MM_DD}"
TT_INCOMING_PATH="${TT_INCOMING_PATH:-$BASE_PATH/input/bkp/in/$TODAY_YYYY_MM_DD}"
TT_OUTGOING_PATH="${TT_OUTGOING_PATH:-$BASE_PATH/input/bkp/out/$YESTERDAY_YYYY_MM_DD}"

# Allow processing multiple days (comma-separated list of days to look back)
LOOKBACK_DAYS=${LOOKBACK_DAYS:-1}  # Default: look back 1 day

# Array of source directories to process
SOURCE_DIRS=(
    "$TT_INCOMING_PATH"
    "$TT_OUTGOING_PATH"
    "$RTGS_INCOMING_PATH"
    "$RTGS_OUTGOING_PATH"
)

# Function to print colored output
print_message() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] ✅ $1${NC}"
}

print_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️ $1${NC}"
}

print_info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] ℹ️ $1${NC}"
}

print_separator() {
    echo -e "${BLUE}============================================================${NC}"
}

# Function to generate date-based paths for multiple days
generate_date_paths() {
    local base_path=$1
    local path_format=$2  # YYYYMMDD or YYYY-MM-DD
    local days_back=${3:-$LOOKBACK_DAYS}
    local paths=""
    
    for ((i=0; i<=days_back; i++)); do
        local date_str
        if [ "$path_format" == "YYYYMMDD" ]; then
            date_str=$(date -d "$i days ago" +%Y%m%d 2>/dev/null || date -v-${i}d +%Y%m%d)
            paths="$paths ${base_path}${date_str}"
        else
            date_str=$(date -d "$i days ago" +%Y-%m-%d 2>/dev/null || date -v-${i}d +%Y-%m-%d)
            paths="$paths ${base_path}${date_str}"
        fi
    done
    
    echo "$paths"
}

# Function to run Rails commands inside Docker container
run_rails_command() {
    local command="$1"
    docker compose exec -T "$SERVICE_NAME" bundle exec rails runner "$command"
}

# Function to process files from multiple remote directories with dynamic dates
process_from_remote() {
    print_separator
    print_info "🚀 RTGS Processing Started"
    print_info "Limit: $LIMIT"
    print_info "Environment: ${RAILS_ENV:-production}"
    print_info "Date: $(date)"
    print_info "Looking back $LOOKBACK_DAYS days"
    print_separator
    
    # Build directories with date expansion
    local dirs_ruby=""
    local dir_count=0
    
    # Show what directories we're checking
    print_info "📂 Source Directories:"
    
    # TT Incoming (YYYY-MM-DD format)
    for ((i=0; i<=LOOKBACK_DAYS; i++)); do
        local date_str=$(date -d "$i days ago" +%Y-%m-%d 2>/dev/null || date -v-${i}d +%Y-%m-%d)
        local path="$BASE_PATH/input/bkp/in/$date_str"
        print_info "  TT_INCOMING: $path"
        dirs_ruby="$dirs_ruby'$path', "
        ((dir_count++))
    done
    
    # TT Outgoing (YYYY-MM-DD format)
    for ((i=0; i<=LOOKBACK_DAYS; i++)); do
        local date_str=$(date -d "$i days ago" +%Y-%m-%d 2>/dev/null || date -v-${i}d +%Y-%m-%d)
        local path="$BASE_PATH/input/bkp/out/$date_str"
        print_info "  TT_OUTGOING: $path"
        dirs_ruby="$dirs_ruby'$path', "
        ((dir_count++))
    done
    
    # RTGS Incoming (YYYY-MM-DD format)
    for ((i=0; i<=LOOKBACK_DAYS; i++)); do
        local date_str=$(date -d "$i days ago" +%Y-%m-%d 2>/dev/null || date -v-${i}d +%Y-%m-%d)
        local path="$BASE_PATH/input/bkp/in/$date_str"
        print_info "  RTGS_INCOMING: $path"
        dirs_ruby="$dirs_ruby'$path', "
        ((dir_count++))
    done
    
    # RTGS Outgoing (YYYYMMDD format - different format!)
    for ((i=0; i<=LOOKBACK_DAYS; i++)); do
        local date_str=$(date -d "$i days ago" +%Y%m%d 2>/dev/null || date -v-${i}d +%Y%m%d)
        local path="$BASE_PATH/input_rtgs_via_swift/MX_OUT/$date_str"
        print_info "  RTGS_OUTGOING: $path"
        dirs_ruby="$dirs_ruby'$path', "
        ((dir_count++))
    done
    
    print_separator
    print_info "Total directories to check: $dir_count"
    
    local rails_command="
        # Define all source directories with dynamic dates
        remote_dirs = [${dirs_ruby}]
        
        limit = $([ "$LIMIT" != "all" ] && echo "$LIMIT" || echo "nil")
        lookback_days = $LOOKBACK_DAYS
        
        puts \"\n🔍 Looking for files in \#{remote_dirs.count} directories...\"
        
        remote_service = RemoteFileService.new(
            host: AMLOCK_SERVER_IP,
            username: AMLOCK_USER_NAME,
            password: AMLOCK_PASSWORD
        )
        
        all_files = []
        dir_stats = {}
        
        remote_dirs.each do |remote_path|
            begin
                # Check if directory exists first
                if remote_service.file_exists?(remote_path)
                    files = remote_service.list_rtgs_files(remote_path) || []
                    if files.any?
                        puts \"  ✅ \#{remote_path}: \#{files.count} files\"
                        all_files.concat(files.map { |f| { path: remote_path, file: f } })
                    else
                        puts \"  ⚠️ \#{remote_path}: No files\"
                    end
                else
                    puts \"  ❌ \#{remote_path}: Directory does not exist\"
                end
                dir_stats[remote_path] = files ? files.count : 0
            rescue => e
                puts \"  ❌ \#{remote_path}: Error - \#{e.message}\"
                dir_stats[remote_path] = 0
            end
        end
        
        if all_files.empty?
            puts \"\n❌ No RTGS files found in any directory\"
            puts \"\n📊 Directory Summary:\"
            dir_stats.each do |path, count|
                puts \"  \#{path}: \#{count} files\"
            end
            exit 0
        end
        
        puts \"\n📊 Total files found: \#{all_files.count}\"
        
        # Sort files by directory priority (TT_INCOMING first, etc.)
        priority_order = ['in', 'out', 'MX_OUT']
        all_files.sort_by! do |item|
            path = item[:path]
            priority = priority_order.index { |p| path.include?(p) } || 999
            [priority, item[:file].name]
        end
        
        files_to_process = limit ? all_files.first(limit) : all_files
        
        puts \"\n📥 Processing \#{files_to_process.count} files\"
        
        results = {
            processed: 0,
            failed: 0,
            skipped: 0,
            by_directory: {}
        }
        
        download_dir = Rails.root.join('tmp', 'rtgs_downloads')
        FileUtils.mkdir_p(download_dir)
        
        files_to_process.each do |item|
            file = item[:file]
            remote_path = item[:path]
            file_name = file.name
            
            # Determine source type from path
            source_type = if remote_path.include?('MX_OUT')
                'RTGS_OUTGOING'
            elsif remote_path.include?('in')
                if remote_path.include?('rtgs_via_swift')
                    'RTGS_INCOMING'
                else
                    'TT_INCOMING'
                end
            elsif remote_path.include?('out')
                'TT_OUTGOING'
            else
                'UNKNOWN'
            end
            
            # Track directory stats
            dir_key = source_type
            results[:by_directory][dir_key] ||= { processed: 0, failed: 0, skipped: 0 }
            
            puts \"\n📄 Processing: \#{file_name}\"
            puts \"  Source: \#{source_type}\"
            puts \"  Path: \#{remote_path}\"
            
            local_path = download_dir.join(file_name).to_s
            remote_full_path = File.join(remote_path, file_name)
            
            unless remote_service.download_file(remote_full_path, local_path)
                puts \"  ❌ Download failed\"
                results[:failed] += 1
                results[:by_directory][dir_key][:failed] += 1
                next
            end
            
            content = File.read(local_path)
            parser = ManualRtgsParserService.new(content)
            parsed = parser.call
            
            if !parsed || parsed['reference'].blank?
                puts \"  ❌ Parse failed or no reference\"
                results[:failed] += 1
                results[:by_directory][dir_key][:failed] += 1
                FileUtils.rm_f(local_path)
                next
            end
            
            transaction = Transaction.find_or_initialize_by(rtgs_reference: parsed['reference'])
            
            if transaction.persisted?
                puts \"  ⏭️ Already exists (ID: \#{transaction.id})\"
                results[:skipped] += 1
                results[:by_directory][dir_key][:skipped] += 1
                FileUtils.rm_f(local_path)
                next
            end
            
            # Build transaction
            transaction.request_id = parsed['requestId']
            transaction.transaction_direction = parsed['transactionDirection']
            transaction.transaction_amount = parsed['transactionAmount']
            transaction.transaction_currency = parsed['transactionCurrency']
            transaction.transaction_date = parsed['transactionDate']
            transaction.rtgs_reference = parsed['reference']
            transaction.parties = parsed['parties']
            transaction.raw_rtgs_message = content
            transaction.screening_status = 'pending'
            
            # Store source type for tracking
            transaction.clearing_system_ref = source_type
            
            if Transaction.column_names.include?('narrative') && parsed['narrative'].present?
                transaction.narrative = parsed['narrative']
            end
            
            if transaction.save
                puts \"  ✅ Transaction created (ID: \#{transaction.id}) from \#{source_type}\"
                results[:processed] += 1
                results[:by_directory][dir_key][:processed] += 1
                RtgsScreeningJob.perform_later(content, transaction.id)
                puts \"  🔍 Screening queued\"
            else
                puts \"  ❌ Save failed: \#{transaction.errors.full_messages.join(', ')}\"
                results[:failed] += 1
                results[:by_directory][dir_key][:failed] += 1
            end
            
            FileUtils.rm_f(local_path)
        end
        
        puts \"\"
        print_separator
        puts \"📊 Overall Summary:\"
        puts \"  Processed: \#{results[:processed]}\"
        puts \"  Failed: \#{results[:failed]}\"
        puts \"  Skipped: \#{results[:skipped]}\"
        puts \"  Total: \#{results[:processed] + results[:failed] + results[:skipped]}\"
        
        puts \"\n📊 Per Source Summary:\"
        results[:by_directory].each do |source, stats|
            total = stats[:processed] + stats[:failed] + stats[:skipped]
            puts \"  \#{source}:\"
            puts \"    Processed: \#{stats[:processed]}\"
            puts \"    Failed: \#{stats[:failed]}\"
            puts \"    Skipped: \#{stats[:skipped]}\"
            puts \"    Total: \#{total}\"
        end
        print_separator
        
        results
    "
    
    run_rails_command "$rails_command"
}

# Function to process files from a specific source with date-based path
process_from_source() {
    local source_type="$1"
    local source_path=""
    local path_format=""
    
    case "$source_type" in
        TT_INCOMING)
            path_format="YYYY-MM-DD"
            source_path="$BASE_PATH/input/bkp/in"
            ;;
        TT_OUTGOING)
            path_format="YYYY-MM-DD"
            source_path="$BASE_PATH/input/bkp/out"
            ;;
        RTGS_INCOMING)
            path_format="YYYY-MM-DD"
            source_path="$BASE_PATH/input/bkp/in"
            ;;
        RTGS_OUTGOING)
            path_format="YYYYMMDD"
            source_path="$BASE_PATH/input_rtgs_via_swift/MX_OUT"
            ;;
        *)
            print_error "Unknown source type: $source_type"
            echo "Available: TT_INCOMING, TT_OUTGOING, RTGS_INCOMING, RTGS_OUTGOING"
            return 1
            ;;
    esac
    
    # Get the specific date or use today
    local target_date="${2:-$(date +%Y-%m-%d)}"
    
    # Convert date format if needed
    if [ "$path_format" == "YYYYMMDD" ]; then
        target_date=$(date -d "$target_date" +%Y%m%d 2>/dev/null || echo "$target_date")
    fi
    
    local full_path="$source_path/$target_date"
    
    print_separator
    print_info "🚀 RTGS Processing Started"
    print_info "Source: $source_type"
    print_info "Path: $full_path"
    print_info "Limit: $LIMIT"
    print_separator
    
    # Also check previous days if LOOKBACK_DAYS > 0
    local date_paths="'$full_path'"
    for ((i=1; i<=LOOKBACK_DAYS; i++)); do
        local prev_date
        if [ "$path_format" == "YYYYMMDD" ]; then
            prev_date=$(date -d "$target_date - $i days" +%Y%m%d 2>/dev/null || echo "")
        else
            prev_date=$(date -d "$target_date - $i days" +%Y-%m-%d 2>/dev/null || echo "")
        fi
        if [ -n "$prev_date" ]; then
            date_paths="$date_paths, '$source_path/$prev_date'"
        fi
    done
    
    local rails_command="
        remote_dirs = [$date_paths]
        limit = $([ "$LIMIT" != "all" ] && echo "$LIMIT" || echo "nil")
        
        puts \"🔍 Looking for files in \${remote_dirs.count} directories...\"
        
        remote_service = RemoteFileService.new(
            host: AMLOCK_SERVER_IP,
            username: AMLOCK_USER_NAME,
            password: AMLOCK_PASSWORD
        )
        
        all_files = []
        remote_dirs.each do |remote_path|
            begin
                files = remote_service.list_rtgs_files(remote_path) || []
                puts \"  \${remote_path}: \${files.count} files\"
                all_files.concat(files.map { |f| { path: remote_path, file: f } })
            rescue => e
                puts \"  ❌ \${remote_path}: Error - \${e.message}\"
            end
        end
        
        if all_files.empty?
            puts 'No RTGS files found'
            exit 0
        end
        
        puts \"Found \${all_files.count} files to process\"
        
        results = {
            processed: 0,
            failed: 0,
            skipped: 0
        }
        
        download_dir = Rails.root.join('tmp', 'rtgs_downloads')
        FileUtils.mkdir_p(download_dir)
        
        files_to_process = limit ? all_files.first(limit) : all_files
        
        files_to_process.each do |item|
            file = item[:file]
            remote_path = item[:path]
            file_name = file.name
            
            puts \"\n📄 Processing: \${file_name}\"
            
            local_path = download_dir.join(file_name).to_s
            remote_full_path = File.join(remote_path, file_name)
            
            unless remote_service.download_file(remote_full_path, local_path)
                puts \"  ❌ Download failed\"
                results[:failed] += 1
                next
            end
            
            content = File.read(local_path)
            parser = ManualRtgsParserService.new(content)
            parsed = parser.call
            
            if !parsed || parsed['reference'].blank?
                puts \"  ❌ Parse failed or no reference\"
                results[:failed] += 1
                FileUtils.rm_f(local_path)
                next
            end
            
            transaction = Transaction.find_or_initialize_by(rtgs_reference: parsed['reference'])
            
            if transaction.persisted?
                puts \"  ⏭️ Already exists (ID: \${transaction.id})\"
                results[:skipped] += 1
                FileUtils.rm_f(local_path)
                next
            end
            
            # Build transaction
            transaction.request_id = parsed['requestId']
            transaction.transaction_direction = parsed['transactionDirection']
            transaction.transaction_amount = parsed['transactionAmount']
            transaction.transaction_currency = parsed['transactionCurrency']
            transaction.transaction_date = parsed['transactionDate']
            transaction.rtgs_reference = parsed['reference']
            transaction.parties = parsed['parties']
            transaction.raw_rtgs_message = content
            transaction.screening_status = 'pending'
            transaction.clearing_system_ref = '$source_type'
            
            if Transaction.column_names.include?('narrative') && parsed['narrative'].present?
                transaction.narrative = parsed['narrative']
            end
            
            if transaction.save
                puts \"  ✅ Transaction created (ID: \${transaction.id})\"
                results[:processed] += 1
                RtgsScreeningJob.perform_later(content, transaction.id)
                puts \"  🔍 Screening queued\"
            else
                puts \"  ❌ Save failed: \${transaction.errors.full_messages.join(', ')}\"
                results[:failed] += 1
            end
            
            FileUtils.rm_f(local_path)
        end
        
        puts \"\"
        print_separator
        puts \"📊 Summary:\"
        puts \"  Processed: \${results[:processed]}\"
        puts \"  Failed: \${results[:failed]}\"
        puts \"  Skipped: \${results[:skipped]}\"
        puts \"  Total: \${results[:processed] + results[:failed] + results[:skipped]}\"
        print_separator
        
        results
    "
    
    run_rails_command "$rails_command"
}

# Function to check status
check_status() {
    print_info "📊 Checking RTGS processing status..."
    
    local rails_command="
        puts '📊 Transaction Summary:'
        puts \"  Total: \#{Transaction.count}\"
        puts \"  Pending: \#{Transaction.where(screening_status: 'pending').count}\"
        puts \"  Processing: \#{Transaction.where(screening_status: 'processing').count}\"
        puts \"  Completed: \#{Transaction.where(screening_status: 'completed').count}\"
        puts \"  Failed: \#{Transaction.where(screening_status: 'failed').count}\"
        
        puts \"\n📋 Latest 5 Transactions:\"
        Transaction.order(created_at: :desc).limit(5).each do |t|
            status = t.screening_status
            result = t.screening_result.is_a?(Hash) ? t.screening_result['result'] || t.screening_result : t.screening_result
            check_result = result.is_a?(Hash) ? result['checkResult'] : 'N/A'
            source = t.clearing_system_ref || 'Unknown'
            puts \"  #\#{t.id}: \#{t.rtgs_reference} - \#{t.transaction_amount} \#{t.transaction_currency} - \#{status} - Source: \#{source}\"
        end
        
        failed = Transaction.where(screening_status: 'failed')
        if failed.any?
            puts \"\n⚠️ Failed Transactions:\"
            failed.each do |t|
                puts \"  #\#{t.id}: \#{t.rtgs_reference} - \#{t.screening_result}\"
            end
        end
    "
    
    run_rails_command "$rails_command"
}

# Function to list available directories
list_directories() {
    print_info "📂 Checking available directories..."
    
    local today_ymd=$(date +%Y-%m-%d)
    local today_ymd_compact=$(date +%Y%m%d)
    local yesterday_ymd=$(date -d "yesterday" +%Y-%m-%d 2>/dev/null || date -v-1d +%Y-%m-%d)
    
    echo ""
    echo "TT_INCOMING: $BASE_PATH/input/bkp/in/$today_ymd"
    echo "TT_INCOMING (yesterday): $BASE_PATH/input/bkp/in/$yesterday_ymd"
    echo "TT_OUTGOING: $BASE_PATH/input/bkp/out/$today_ymd"
    echo "TT_OUTGOING (yesterday): $BASE_PATH/input/bkp/out/$yesterday_ymd"
    echo "RTGS_INCOMING: $BASE_PATH/input/bkp/in/$today_ymd"
    echo "RTGS_INCOMING (yesterday): $BASE_PATH/input/bkp/in/$yesterday_ymd"
    echo "RTGS_OUTGOING: $BASE_PATH/input_rtgs_via_swift/MX_OUT/$today_ymd_compact"
    echo "RTGS_OUTGOING (yesterday): $BASE_PATH/input_rtgs_via_swift/MX_OUT/$(date -d 'yesterday' +%Y%m%d 2>/dev/null || date -v-1d +%Y%m%d)"
    echo ""
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  process [limit]                    - Process files from ALL source directories"
    echo "  source [SOURCE] [date] [limit]    - Process files from specific source"
    echo "  status                             - Check processing status"
    echo "  list                               - List available directories"
    echo "  help                               - Show this help message"
    echo ""
    echo "Sources:"
    echo "  TT_INCOMING   - TT Incoming files (path: input/bkp/in/YYYY-MM-DD)"
    echo "  TT_OUTGOING   - TT Outgoing files (path: input/bkp/out/YYYY-MM-DD)"
    echo "  RTGS_INCOMING - RTGS Incoming files (path: input/bkp/in/YYYY-MM-DD)"
    echo "  RTGS_OUTGOING - RTGS Outgoing files (path: input_rtgs_via_swift/MX_OUT/YYYYMMDD)"
    echo ""
    echo "Options:"
    echo "  limit          - Number of files to process (default: all)"
    echo "  date           - Date for specific source (default: today)"
    echo ""
    echo "Environment Variables:"
    echo "  SERVICE_NAME           - Docker service name (default: imtz_aml-web)"
    echo "  RAILS_ENV              - Rails environment (default: production)"
    echo "  LOOKBACK_DAYS          - Number of days to look back (default: 1)"
    echo ""
    echo "Examples:"
    echo "  $0 process 5                      - Process 5 files from ALL directories"
    echo "  $0 process all                    - Process ALL files from ALL directories"
    echo "  $0 source TT_INCOMING 5           - Process 5 files from today's TT_INCOMING"
    echo "  $0 source TT_OUTGOING 2026-08-20 - Process from specific date"
    echo "  $0 source RTGS_OUTGOING 20260821  - Process from specific date (YYYYMMDD format)"
    echo "  $0 status                         - Check current status"
    echo "  $0 list                           - List available directories"
    echo ""
    echo "Path Formats:"
    echo "  TT_INCOMING:   /amlock/Tanzania/RMS/input/bkp/in/YYYY-MM-DD"
    echo "  TT_OUTGOING:   /amlock/Tanzania/RMS/input/bkp/out/YYYY-MM-DD"
    echo "  RTGS_INCOMING: /amlock/Tanzania/RMS/input/bkp/in/YYYY-MM-DD"
    echo "  RTGS_OUTGOING: /amlock/Tanzania/RMS/input_rtgs_via_swift/MX_OUT/YYYYMMDD"
    echo ""
}

# Main function
main() {
    if [ -z "$1" ] || [ "$1" == "help" ] || [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
        show_usage
        exit 0
    fi

    case "$1" in
        process)
            if [ -n "$2" ]; then
                LIMIT="$2"
            else
                LIMIT="all"
            fi
            process_from_remote
            ;;
        source)
            if [ -z "$2" ]; then
                print_error "Please specify a source"
                echo "Available: TT_INCOMING, TT_OUTGOING, RTGS_INCOMING, RTGS_OUTGOING"
                exit 1
            fi
            local date_param=""
            if [ -n "$3" ] && [[ "$3" != [0-9]* ]]; then
                # Third parameter is a date
                date_param="$3"
                if [ -n "$4" ]; then
                    LIMIT="$4"
                else
                    LIMIT="all"
                fi
            else
                if [ -n "$3" ]; then
                    LIMIT="$3"
                else
                    LIMIT="all"
                fi
            fi
            process_from_source "$2" "$date_param"
            ;;
        status)
            check_status
            ;;
        list)
            list_directories
            ;;
        *)
            print_error "Unknown command: $1"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
