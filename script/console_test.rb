# script/console_test.rb
# Run with: rails console < script/console_test.rb

# Sample messages
sample_incoming = '{1:F01IMBLTZTZXXX0623162310}{2:O1031623260623NLCBTZTXFIN06231623102606231623N}{3:{103:TIS}{113:NNNN}{108:001FTOL261740709}{119:STP}{111:001}{121:e0fa079a-08d4-4785-827c-517df485e1ef}}{4:
:20:001FTOL261740709
:23B:CRED
:32A:260623TZS174308602,00
:33B:TZS174308602,00
:50F:/041103002729
1/REDINGTON TANZANIA LIMITED
2/
3/TZ/DAR ES SALAAM/
:52A:NLCBTZTXFIN
:57A:IMBLTZTZXXX
:59:/30021830001
Liveal Limited
Dar Es Salaam
Tanzania
:70:Payment to LIVEAL LIMITED
:71A:OUR
:72:Payment to LIVEAL LIMITED
-}'

# Test parsing
puts "Testing incoming transaction..."
parser = RtgsParserService.new(sample_incoming)
result = parser.call

if result
  puts "✅ Success!"
  puts "Amount: #{result['transactionAmount']} #{result['transactionCurrency']}"
  puts "Debtor: #{result['parties'].find { |p| p['partyType'] == 'Debtor' }['fullName']}"
  puts "Creditor: #{result['parties'].find { |p| p['partyType'] == 'Creditor' }['fullName']}"
  
  # Create transaction
  transaction = Transaction.new(
    request_id: result['requestId'],
    transaction_direction: result['transactionDirection'],
    transaction_type: result['transactionType'],
    transaction_amount: result['transactionAmount'],
    transaction_currency: result['transactionCurrency'],
    transaction_date: result['transactionDate'],
    reference: result['reference'],
    narrative: result['narrative'],
    bank_code: result['bankCode'],
    parties: result['parties'],
    raw_data: result,
    raw_fields: result['rawFields'],
    raw_message: sample_incoming,
    status: 'PENDING_SCREENING'
  )
  
  if transaction.save
    puts "✅ Transaction saved with ID: #{transaction.id}"
  else
    puts "❌ Failed to save: #{transaction.errors.full_messages}"
  end
else
  puts "❌ Failed to parse"
end
