require "../spec_helper"

describe Nacha::EntryDetail do
  describe "build" do
    it "formats the data correctly" do
      example = "62210264791931945123488995   0000062432418            Billy Bonka             0000000000000001"
      example.bytesize.should eq(Nacha::File::RECORD_SIZE)

      io = IO::Memory.new
      entry = Nacha::EntryDetail.new(
        transaction_code: :checking_credit,
        dfi_routing_number: "102647919",
        dfi_account_number: "31945123488995",
        amount: 62432, # $624.32
        individual_identification_number: "418",
        individual_name: "Billy Bonka",
        trace_number: "1",
      )
      entry.build(io)
      io.to_s.should eq(example)
    end
  end

  describe "parse" do
    it "parses the data correctly" do
      line = "6270210000211230000099       00010000003213211234     DARON BERGSTROM       S 0012345678912345"
      entry_detail = Nacha::EntryDetail.parse(line)
      entry_detail.transaction_code.should eq(Nacha::EntryDetail::TransactionCode::CheckingDebit)
      entry_detail.dfi_routing_number.should eq("021000021")
      entry_detail.dfi_account_number.should eq("1230000099")
      entry_detail.amount.should eq(1000000)
      entry_detail.individual_name.should eq("DARON BERGSTROM")
    end

    context "errors" do
      it "raises when it's not a EntryDetail" do
        line = "101 021000021 3210001232209291648D094101WELLS FARGO BANK       ACME CORPORATION               "
        expect_raises(Nacha::ParserError, "Invalid Type Code '1' for Entry Detail") do
          Nacha::EntryDetail.parse(line)
        end
      end

      it "raises when it's the wrong length" do
        line = "627021"
        expect_raises(Nacha::ParserError, "Invalid Record Length '6' for Entry Detail") do
          Nacha::EntryDetail.parse(line)
        end
      end
    end
  end
end
