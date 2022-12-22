require "../spec_helper"

describe Nacha::Parser do
  context "with a single debit file" do
    it "parses the correct information" do
      parser = Nacha::Parser.new
      ach = File.read("./spec/fixtures/single_debit.ach")
      details = parser.parse(ach)

      details

      # details.should be_a(Nacha::File)
      # details.batches.size.should eq(1)
      # details.header.immediate_destination_name.should eq("WELLS FARGO BANK")
      # details.header.immediate_origin_name.should eq("ACME CORPORATION")
    end
  end
end
