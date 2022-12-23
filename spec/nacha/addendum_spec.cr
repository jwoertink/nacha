require "../spec_helper"

describe Nacha::Addendum do
  describe "build" do
    it "formats the data correctly" do
      example = "705Credit Store Account                                                            00010000001"
      example.bytesize.should eq(Nacha::File::RECORD_SIZE)

      io = IO::Memory.new

      addenda = Nacha::Addendum.new(
        entry_detail_sequence_number: 1,
        payment_related_information: "Credit Store Account",
        sequence_number: 1,
      )
      addenda.build(io)
      io.to_s.should eq(example)
    end
  end

  describe "parse" do
    it "parses the data correctly" do
      line = "705Credit Store Account                                                            00010000001"
      addendum = Nacha::Addendum.parse(line)
      addendum.entry_detail_sequence_number.should eq(1)
      addendum.payment_related_information.should eq("Credit Store Account")
      addendum.sequence_number.should eq(1)
    end

    context "errors" do
      it "raises when it's not a Addendum" do
        line = "5200ACME CORPORATION                    1233211212WEBONLINEPYMT2209292209302731012000120000261"
        expect_raises(Nacha::ParserError, "Invalid Type Code '5' for Addendum") do
          Nacha::Addendum.parse(line)
        end
      end

      it "raises when it's the wrong length" do
        line = "705"
        expect_raises(Nacha::ParserError, "Invalid Record Length '3' for Addendum") do
          Nacha::Addendum.parse(line)
        end
      end
    end
  end
end
