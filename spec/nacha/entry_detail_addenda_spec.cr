require "../spec_helper"

describe Nacha::EntryDetailAddenda do
  describe "build" do
    it "formats the data correctly" do
      example = "705                                                                                00010000004"
      example.bytesize.should eq(Nacha::File::RECORD_SIZE)

      io = IO::Memory.new
      entry = Nacha::EntryDetail.new(
        transaction_code: :checking_credit,
        dfi_routing_number: "102647919",
        dfi_account_number: "31945123488995",
        amount: 62432, # $624.32
        individual_identification_number: "418",
        individual_name: "Billy Bonka",
        trace_number: 4
      )
      addenda = Nacha::EntryDetailAddenda.new(entry_detail: entry)
      addenda.build(io)
      io.to_s.should eq(example)
    end
  end
end
