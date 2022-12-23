require "../spec_helper"

describe Nacha::BatchHeader do
  describe "build" do
    it "formats the data correctly" do
      example = "5220My Company                          1234567890WEBPAY OUT   221207221207   1071000500000001"
      example.bytesize.should eq(Nacha::File::RECORD_SIZE)

      current_time = Time.utc(2022, 12, 7, 14, 17, 0)

      io = IO::Memory.new
      batch_header = Nacha::BatchHeader.new(
        service_class_code: :credit,
        company_name: "My Company",
        company_identification: "1234567890",
        standard_entry_class: :web,
        company_entry_description: "PAY OUT",
        effective_entry_date: current_time,
        company_descriptive_date: current_time,
        originating_dfi_identification: "07100050",
        originator_status_code: '1',
      )
      batch_header.build(io)
      io.to_s.should eq(example)
      io.to_s.size.should eq(94)
    end
  end

  describe "parse" do
    it "parses the data correctly" do
      line = "5200ACME CORPORATION                    1233211212WEBONLINEPYMT2209292209302731012000120000261"
      batch_header = Nacha::BatchHeader.parse(line)
      batch_header.service_class_code.should eq(Nacha::Batch::ServiceClassCode::Mixed)
      batch_header.company_name.should eq("ACME CORPORATION")
      batch_header.standard_entry_class.should eq(Nacha::BatchHeader::StandardEntryClass::WEB)
      batch_header.company_entry_description.should eq("ONLINEPYMT")
    end

    context "errors" do
      it "raises when it's not a BatchHeader" do
        line = "6270210000211230000099       00010000003213211234     DARON BERGSTROM       S 0012345678912345"
        expect_raises(Nacha::ParserError, "Invalid Type Code '6' for Batch Header") do
          Nacha::BatchHeader.parse(line)
        end
      end

      it "raises when it's the wrong length" do
        line = "5200"
        expect_raises(Nacha::ParserError, "Invalid Record Length '4' for Batch Header") do
          Nacha::BatchHeader.parse(line)
        end
      end
    end
  end
end
