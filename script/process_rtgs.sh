#!/bin/bash
# script/process_rtgs.sh
# RTGS Processing Script - Runs commands inside Docker container

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Find the Rails root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(dirname "$SCRIPT_DIR")"

# Default values
LIMIT=${1:-"all"}
RAILS_ENV=${RAILS_ENV:-"production"}

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

# Function to run Rails commands inside Docker container
run_rails_command() {
    cd "$APP_DIR"
    docker compose exec -T imtz_aml-web bundle exec rails runner "$1"
}

# Function to process files directly from remote
process_from_remote() {
    print_info "🚀 RTGS Processing Started"
    print_info "Limit: $LIMIT"
    print_info "Environment: $RAILS_ENV"
    print_info "="*60
    
    RAILS_COMMAND="
        remote_path = '/amlock/Tanzania/RMS/mxt_to_mt/rtgs_source_only'
        limit = $([ "$LIMIT" != "all" ] && echo "$LIMIT" || echo "nil")
        
        puts \"🔍 Looking for files in: \#{remote_path}\"
        
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
        
        puts \"Found \#{files_to_process.count} files to process\"
        
        processed = 0
        failed = 0
        skipped = 0
        
        download_dir = Rails.root.join('tmp', 'rtgs_downloads')
        FileUtils.mkdir_p(download_dir)
        
        files_to_process.each do |file|
            file_name = file.name
            puts \"\n📄 Processing: \#{file_name}\"
            
            local_path = download_dir.join(file_name).to_s
            remote_full_path = File.join(remote_path, file_name)
            
            unless remote_service.download_file(remote_full_path, local_path)
                puts \"  ❌ Download failed\"
                failed += 1
                next
            end
            
            content = File.read(local_path)
            parser = ManualRtgsParserService.new(content)
            parsed = parser.call
            
            if !parsed || parsed['reference'].blank?
                puts \"  ❌ Parse failed or no reference\"
                failed += 1
                FileUtils.rm_f(local_path)
                next
            end
            
            transaction = Transaction.find_or_initialize_by(rtgs_reference: parsed['reference'])
            
            if transaction.persisted?
                puts \"  ⏭️ Already exists (ID: \#{transaction.id})\"
                skipped += 1
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
            
            if Transaction.column_names.include?('narrative') && parsed['narrative'].present?
                transaction.narrative = parsed['narrative']
            end
            
            if transaction.save
                puts \"  ✅ Transaction created (ID: \#{transaction.id})\"
                processed += 1
                RtgsScreeningJob.perform_later(content, transaction.id)
                puts \"  🔍 Screening queued\"
            else
                puts \"  ❌ Save failed: \#{transaction.errors.full_messages.join(', ')}\"
                failed += 1
            end
            
            FileUtils.rm_f(local_path)
        end
        
        puts \"\n\" + \"=\" * 60
        puts \"📊 Summary:\"
        puts \"  Processed: \#{processed}\"
        puts \"  Failed: \#{failed}\"
        puts \"  Skipped: \#{skipped}\"
        puts \"  Total: \#{processed + failed + skipped}\"
    "
    
    run_rails_command "$RAILS_COMMAND"
}

# Function to check status
check_status() {
    print_info "📊 Checking RTGS processing status..."
    
    RAILS_COMMAND="
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
            puts \"  #\#{t.id}: \#{t.rtgs_reference} - \#{t.transaction_amount} \#{t.transaction_currency} - \#{status} - \#{check_result}\"
        end
        
        failed = Transaction.where(screening_status: 'failed')
        if failed.any?
            puts \"\n⚠️ Failed Transactions:\"
            failed.each do |t|
                puts \"  #\#{t.id}: \#{t.rtgs_reference} - \#{t.screening_result}\"
            end
        end
    "
    
    run_rails_command "$RAILS_COMMAND"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  process [limit]  - Download and process RTGS files from remote"
    echo "  status           - Check processing status"
    echo "  help             - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 process 5     - Process 5 files from remote"
    echo "  $0 process all   - Process all files from remote"
    echo "  $0 status        - Check current status"
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
        status)
            check_status
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
