#!/bin/bash
# Author: Abdillah Muna | abdillah.muna@imbank.co.tz | abdimuna1@gmail.com
# Date: 20, August 2026
# script/process_rtgs.sh
# Author: Abdillah Muna
# RTGS Processing Script - Downloads and processes RTGS files via Docker
# Supports multiple source directories: TT_INCOMING, TT_OUTGOING, RTGS_INCOMING, RTGS_OUTGOING

# #################### USAGE ####################
#  Process all files from ALL directories
# ./process_rtgs.sh process all

# # Process 5 files from ALL directories
# ./process_rtgs.sh process 5

# # Process only TT_INCOMING files
# ./process_rtgs.sh source TT_INCOMING

# # Process 10 files from TT_OUTGOING only
# ./process_rtgs.sh source TT_OUTGOING 10

# # Process all RTGS_INCOMING files
# ./process_rtgs.sh source RTGS_INCOMING all

# # Check status
# ./process_rtgs.sh status

# # Override paths with environment variables
# export TT_INCOMING_PATH="/custom/path/to/tt_incoming"
# export RTGS_INCOMING_PATH="/custom/path/to/rtgs_incoming"
# ./process_rtgs.sh process 5
# ################################################## 

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

# Define source directories
BASE_PATH="/amlock/Tanzania/RMS/mxt_to_mt"

# You can override these with environment variables
TT_INCOMING_PATH="${TT_INCOMING_PATH:-$BASE_PATH/tt_incoming}"
TT_OUTGOING_PATH="${TT_OUTGOING_PATH:-$BASE_PATH/tt_outgoing}"
RTGS_INCOMING_PATH="${RTGS_INCOMING_PATH:-$BASE_PATH/rtgs_source_only}"
RTGS_OUTGOING_PATH="${RTGS_OUTGOING_PATH:-$BASE_PATH/rtgs_outgoing}"

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

# Function to run Rails commands inside Docker container
run_rails_command() {
    local command="$1"
    docker compose exec -T "$SERVICE_NAME" bundle exec rails runner "$command"
}

# Function to process files from multiple remote directories
process_from_remote() {
    print_separator
    print_info "🚀 RTGS Processing Started"
    print_info "Limit: $LIMIT"
    print_info "Environment: ${RAILS_ENV:-production}"
    print_separator
    
    # Build the directories string for Ruby
    local dirs_ruby=""
    for dir in "${SOURCE_DIRS[@]}"; do
        dirs_ruby="$dirs_ruby'$dir', "
    done
    
    local rails_command="
        # Define multiple source directories
        remote_dirs = [${dirs_ruby}]
        
        limit = $([ "$LIMIT" != "all" ] && echo "$LIMIT" || echo "nil")
        
        puts \"🔍 Looking for files in \${remote_dirs.count} directories...\"
        
        remote_service = RemoteFileService.new(
            host: AMLOCK_SERVER_IP,
            username: AMLOCK_USER_NAME,
            password: AMLOCK_PASSWORD
        )
        
        all_files = []
        dir_stats = {}
        
        remote_dirs.each do |remote_path|
            begin
                puts \"\n📂 Checking: \${remote_path}\"
                files = remote_service.list_rtgs_files(remote_path) || []
                puts \"  Found \${files.count} files\"
                all_files.concat(files.map { |f| { path: remote_path, file: f } })
                dir_stats[remote_path] = files.count
            rescue => e
                puts \"  ❌ Error accessing directory: \${e.message}\"
                dir_stats[remote_path] = 0
            end
        end
        
        if all_files.empty?
            puts \"\n❌ No RTGS files found in any directory\"
            puts \"\n📊 Directory Summary:\"
            dir_stats.each do |path, count|
                puts \"  \${path}: \${count} files\"
            end
            exit 0
        end
        
        puts \"\n📊 Total files found across all directories: \${all_files.count}\"
        puts \"\n📊 Directory Breakdown:\"
        dir_stats.each do |path, count|
            puts \"  \${path}: \${count} files\"
        end
        
        files_to_process = limit ? all_files.first(limit) : all_files
        
        puts \"\n📥 Processing \${files_to_process.count} files\"
        
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
            
            # Track directory stats
            dir_key = File.basename(remote_path)
            results[:by_directory][dir_key] ||= { processed: 0, failed: 0, skipped: 0 }
            
            puts \"\n📄 Processing: \${file_name} (from \${remote_path})\"
            
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
            
            # Store source directory for tracking
            transaction.clearing_system_ref = File.basename(remote_path)
            
            if Transaction.column_names.include?('narrative') && parsed['narrative'].present?
                transaction.narrative = parsed['narrative']
            end
            
            if transaction.save
                puts \"  ✅ Transaction created (ID: \#{transaction.id}) from \${File.basename(remote_path)}\"
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
        puts \"  Processed: \${results[:processed]}\"
        puts \"  Failed: \${results[:failed]}\"
        puts \"  Skipped: \${results[:skipped]}\"
        puts \"  Total: \${results[:processed] + results[:failed] + results[:skipped]}\"
        
        puts \"\n📊 Per Directory Summary:\"
        results[:by_directory].each do |dir, stats|
            total = stats[:processed] + stats[:failed] + stats[:skipped]
            puts \"  \${dir}:\"
            puts \"    Processed: \${stats[:processed]}\"
            puts \"    Failed: \${stats[:failed]}\"
            puts \"    Skipped: \${stats[:skipped]}\"
            puts \"    Total: \${total}\"
        end
        print_separator
        
        results
    "
    
    run_rails_command "$rails_command"
}

# Function to process files from a specific source
process_from_source() {
    local source_type="$1"
    local source_path=""
    
    case "$source_type" in
        TT_INCOMING)
            source_path="$TT_INCOMING_PATH"
            ;;
        TT_OUTGOING)
            source_path="$TT_OUTGOING_PATH"
            ;;
        RTGS_INCOMING)
            source_path="$RTGS_INCOMING_PATH"
            ;;
        RTGS_OUTGOING)
            source_path="$RTGS_OUTGOING_PATH"
            ;;
        *)
            print_error "Unknown source type: $source_type"
            echo "Available: TT_INCOMING, TT_OUTGOING, RTGS_INCOMING, RTGS_OUTGOING"
            return 1
            ;;
    esac
    
    print_separator
    print_info "🚀 RTGS Processing Started"
    print_info "Source: $source_type"
    print_info "Path: $source_path"
    print_info "Limit: $LIMIT"
    print_separator
    
    local rails_command="
        remote_path = '$source_path'
        limit = $([ "$LIMIT" != "all" ] && echo "$LIMIT" || echo "nil")
        
        puts \"🔍 Looking for files in: \${remote_path}\"
        
        remote_service = RemoteFileService.new(
            host: AMLOCK_SERVER_IP,
            username: AMLOCK_USER_NAME,
            password: AMLOCK_PASSWORD
        )
        
        all_files = remote_service.list_rtgs_files(remote_path) || []
        files_to_process = limit ? all_files.first(limit) : all_files
        
        if files_to_process.empty?
            puts 'No RTGS files found'
            exit 0
        end
        
        puts \"Found \${files_to_process.count} files to process\"
        
        results = {
            processed: 0,
            failed: 0,
            skipped: 0
        }
        
        download_dir = Rails.root.join('tmp', 'rtgs_downloads')
        FileUtils.mkdir_p(download_dir)
        
        files_to_process.each do |file|
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

# Function to show usage
show_usage() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  process [limit]                    - Process files from ALL source directories"
    echo "  source [SOURCE] [limit]            - Process files from specific source"
    echo "  status                             - Check processing status"
    echo "  help                               - Show this help message"
    echo ""
    echo "Sources:"
    echo "  TT_INCOMING   - TT Incoming files"
    echo "  TT_OUTGOING   - TT Outgoing files"
    echo "  RTGS_INCOMING - RTGS Incoming files"
    echo "  RTGS_OUTGOING - RTGS Outgoing files"
    echo ""
    echo "Options:"
    echo "  limit          - Number of files to process (default: all)"
    echo ""
    echo "Examples:"
    echo "  $0 process 5                      - Process 5 files from ALL directories"
    echo "  $0 process all                    - Process ALL files from ALL directories"
    echo "  $0 source TT_INCOMING 5           - Process 5 files from TT_INCOMING only"
    echo "  $0 source RTGS_OUTGOING all       - Process ALL files from RTGS_OUTGOING"
    echo "  $0 status                         - Check current status"
    echo ""
    echo "Environment Variables:"
    echo "  SERVICE_NAME           - Docker service name (default: imtz_aml-web)"
    echo "  RAILS_ENV              - Rails environment (default: production)"
    echo "  TT_INCOMING_PATH       - Override TT_INCOMING path"
    echo "  TT_OUTGOING_PATH       - Override TT_OUTGOING path"
    echo "  RTGS_INCOMING_PATH     - Override RTGS_INCOMING path"
    echo "  RTGS_OUTGOING_PATH     - Override RTGS_OUTGOING path"
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
            if [ -n "$3" ]; then
                LIMIT="$3"
            else
                LIMIT="all"
            fi
            process_from_source "$2"
            ;;
        status)
            check_status
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
