require "../spec_helper"

describe Nacha::EntryDetail do
  describe "build" do
    it "formats the data correctly" do
      example = "62210264791931945123488995   0000062432            418           Billy Bonka  0000000000000001"

      io = IO::Memory.new
      entry = Nacha::EntryDetail.new(
        transaction_code: :checking_credit,
        dfi_routing_number: "102647919",
        dfi_account_number: "31945123488995",
        amount: 62432, # $624.32
        individual_identification_number: "418",
        individual_name: "Billy Bonka",
      )
      entry.build(io)
      io.to_s.should eq(example)
    end
  end
end
