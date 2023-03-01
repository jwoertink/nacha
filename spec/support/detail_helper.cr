# Build an EntryDetail
module DetailHelper
  def build_entry_detail(**args) : Nacha::EntryDetail
    Nacha::EntryDetail.new(
      transaction_code: args[:transaction_code]? || Nacha::EntryDetail::TransactionCode::CheckingCredit,
      dfi_routing_number: args[:dfi_routing_number]? || Faker::Number.number(9).to_s,
      dfi_account_number: args[:dfi_account_number]? || Faker::Number.between(12, 15).to_s,
      amount: args[:amount]? || Random.rand(10000) + 5000,
      individual_identification_number: args[:individual_identification_number]? || "",
      individual_name: args[:individual_name]? || Faker::Name.name,
      trace_number: args[:trace_number]? || "1".rjust(7, '0')
    )
  end
end
