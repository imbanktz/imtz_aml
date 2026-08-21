# In Rails console or add to config/initializers/console_helpers.rb
def process_rtgs_async(rtgs_message)
  # Create the transaction and enqueue the job
  parser = RtgsParserService.new(rtgs_message)
  parsed_data = parser.call
  
  transaction = Transaction.create(
    request_id: parsed_data[:requestId],
    transaction_direction: parsed_data[:transactionDirection],
    transaction_amount: parsed_data[:transactionAmount].to_d / 100.0,
    transaction_currency: parsed_data[:transactionCurrency],
    transaction_date: parsed_data[:transactionDate],
    clearing_system_ref: parsed_data[:clearingSystemRef],
    parties: parsed_data[:parties],
    agents: parsed_data[:agents],
    narratives: parsed_data[:narratives],
    processing_type: parsed_data[:processingType] || 'CHECK',
    profile: parsed_data[:profile] || 'Tanzania',
    profile_name: parsed_data[:profileName] || 'Tanzania',
    raw_rtgs_message: rtgs_message,
    rtgs_reference: rtgs_message.match(/:20:([^\n:]+)/)&.[](1)&.strip,
    screening_status: 'queued'
  )
  
  # Enqueue the job
  RtgsScreeningJob.perform_later(rtgs_message, transaction.id)
  
  puts "✅ Transaction #{transaction.id} queued for screening"
  puts "Status URL: http://localhost:3000/api/rtgs/status/#{transaction.id}"
  
  transaction
end

# Test the async processing
sample_rtgs = '{1:F01IMBLTZTZXXX0623162310}{2:O1031623260623NLCBTZTXFIN06231623102606231623N}{3:{103:TIS}{113:NNNN}{108:001FTOL261740709}{119:STP}{111:001}{121:e0fa079a-08d4-4785-827c-517df485e1ef}}{4::20:001FTOL261740709:23B:CRED:32A:260623TZS174308602,00:33B:TZS174308602,00:50F:/041103002729 1/REDINGTON TANZANIA LIMITED 2/ 3/TZ/DAR ES SALAAM/:52A:NLCBTZTXFIN:57A:IMBLTZTZXXX:59:/30021830001 Liveal Limited Dar Es Salaam Tanzania:70:Payment to LIVEAL LIMITED:71A:OUR:72:Payment to LIVEAL LIMITED-}'

transaction = process_rtgs_async(sample_rtgs)

# Check status
def check_status(transaction_id)
  response = HTTParty.get("http://localhost:8080/api/v1/rtgs/status/#{transaction_id}")
  puts JSON.pretty_generate(JSON.parse(response.body))
end

check_status(transaction.id)
