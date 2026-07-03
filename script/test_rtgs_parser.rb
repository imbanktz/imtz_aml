# script/test_rtgs_parser.rb
#!/usr/bin/env ruby
# Run with: rails runner script/test_rtgs_parser.rb

puts "=" * 80
puts "RTGS Parser Test Script"
puts "=" * 80

# Sample Incoming MT103 Message
incoming_message = <<~MT103
{1:F01IMBLTZTZXXX0623162310}{2:O1031623260623NLCBTZTXFIN06231623102606231623N}{3:{103:TIS}{113:NNNN}{108:001FTOL261740709}{119:STP}{111:001}{121:e0fa079a-08d4-4785-827c-517df485e1ef}}{4:
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
-}
MT103

# Sample Outgoing MT103 Message
outgoing_message = <<~MT103
{1:F01IMBLTZTZXXXX0000000000}{2:I103NMIBTZTZXXXXN}{3:{103:TIS}{108:TZ629073    }{111:001}{121:b8b863fe-f86d-49ab-9fc3-ba83b957fe32}}{4:
:20:000000561239
:23B:CRED
:32A:260623TZS670000,
:33B:TZS670000,
:50F:/30032404003
1/COMPLAST AFRICA LIMITED
2/PLT 10 LONGIDO STR
3/TZ/UPANGA DAR ES SALAAM
:57A:NMIBTZTZXXX
:59:/24210072392
BERNADETHA SHOO
:70:TBS contract paymentOFFICE EXPENSE
:71A:OUR
:72:/REC/FIVUSEROMNI
-}
MT103

puts "\n📝 Testing Incoming Transaction..."
puts "-" * 80

# Test Incoming
incoming_parser = RtgsParserService.new(incoming_message)
incoming_result = incoming_parser.call

if incoming_result
  puts "✅ Incoming Transaction Parsed Successfully!"
  puts "\n📊 Parsed Data:"
  puts "  Request ID: #{incoming_result['requestId']}"
  puts "  Direction: #{incoming_result['transactionDirection']}"
  puts "  Type: #{incoming_result['transactionType']}"
  puts "  Amount: #{incoming_result['transactionAmount']} #{incoming_result['transactionCurrency']}"
  puts "  Date: #{incoming_result['transactionDate']}"
  puts "  Reference: #{incoming_result['reference']}"
  puts "  Narrative: #{incoming_result['narrative']}"
  puts "  Bank Code: #{incoming_result['bankCode']}"
  
  puts "\n  👤 Parties:"
  incoming_result['parties'].each do |party|
    puts "    - #{party['partyType']}:"
    puts "      ID: #{party['partyId']}"
    puts "      Name: #{party['fullName']}"
    puts "      Nationalities: #{party['nationalities'].join(', ')}"
    puts "      Address: #{party['addressLine']}"
  end
  
  # Save to database
  puts "\n💾 Saving to database..."
  transaction = Transaction.create!(
    request_id: incoming_result['requestId'],
    transaction_direction: incoming_result['transactionDirection'],
    transaction_type: incoming_result['transactionType'],
    transaction_amount: incoming_result['transactionAmount'],
    transaction_currency: incoming_result['transactionCurrency'],
    transaction_date: incoming_result['transactionDate'],
    reference: incoming_result['reference'],
    narrative: incoming_result['narrative'],
    bank_code: incoming_result['bankCode'],
    parties: incoming_result['parties'],
    raw_data: incoming_result,
    raw_fields: incoming_result['rawFields'],
    raw_message: incoming_message,
    status: 'PENDING_SCREENING'
  )
  puts "✅ Transaction saved with ID: #{transaction.id}"
else
  puts "❌ Failed to parse incoming transaction"
end

puts "\n" + "=" * 80
puts "\n📝 Testing Outgoing Transaction..."
puts "-" * 80

# Test Outgoing
outgoing_parser = RtgsParserService.new(outgoing_message)
outgoing_result = outgoing_parser.call

if outgoing_result
  puts "✅ Outgoing Transaction Parsed Successfully!"
  puts "\n📊 Parsed Data:"
  puts "  Request ID: #{outgoing_result['requestId']}"
  puts "  Direction: #{outgoing_result['transactionDirection']}"
  puts "  Type: #{outgoing_result['transactionType']}"
  puts "  Amount: #{outgoing_result['transactionAmount']} #{outgoing_result['transactionCurrency']}"
  puts "  Date: #{outgoing_result['transactionDate']}"
  puts "  Reference: #{outgoing_result['reference']}"
  puts "  Narrative: #{outgoing_result['narrative']}"
  puts "  Bank Code: #{outgoing_result['bankCode']}"
  
  puts "\n  👤 Parties:"
  outgoing_result['parties'].each do |party|
    puts "    - #{party['partyType']}:"
    puts "      ID: #{party['partyId']}"
    puts "      Name: #{party['fullName']}"
    puts "      Nationalities: #{party['nationalities'].join(', ')}"
    puts "      Address: #{party['addressLine']}"
  end
  
  # Save to database
  puts "\n💾 Saving to database..."
  transaction = Transaction.create!(
    request_id: outgoing_result['requestId'],
    transaction_direction: outgoing_result['transactionDirection'],
    transaction_type: outgoing_result['transactionType'],
    transaction_amount: outgoing_result['transactionAmount'],
    transaction_currency: outgoing_result['transactionCurrency'],
    transaction_date: outgoing_result['transactionDate'],
    reference: outgoing_result['reference'],
    narrative: outgoing_result['narrative'],
    bank_code: outgoing_result['bankCode'],
    parties: outgoing_result['parties'],
    raw_data: outgoing_result,
    raw_fields: outgoing_result['rawFields'],
    raw_message: outgoing_message,
    status: 'PENDING_SCREENING'
  )
  puts "✅ Transaction saved with ID: #{transaction.id}"
else
  puts "❌ Failed to parse outgoing transaction"
end

puts "\n" + "=" * 80
puts "📊 Database Summary"
puts "-" * 80

puts "Total Transactions: #{Transaction.count}"
puts "Incoming: #{Transaction.incoming.count}"
puts "Outgoing: #{Transaction.outgoing.count}"
puts "Pending Screening: #{Transaction.pending_screening.count}"

puts "\n✅ Test complete!"
puts "=" * 80
