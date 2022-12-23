require "../spec_helper"

describe Nacha::BatchHeader do
  describe "build" do
    it "formats the data correctly" do
      example = "5200ACME CORPORATION                    1233211212WEBONLINEPYMT2209292209302731012000120000261"
      example.bytesize.should eq(Nacha::File::RECORD_SIZE)

      io = IO::Memory.new
      batch_header = Nacha::BatchHeader.new(
        service_class_code: :mixed,
        company_name: "ACME CORPORATION",
        company_identification: "1233211212",
        standard_entry_class: :web,
        company_entry_description: "ONLINEPYMT",
        effective_entry_date: Time.utc(2022, 9, 30, 12, 0, 0),
        company_descriptive_date: Time.utc(2022, 9, 29, 12, 0, 0),
        settlement_date: 273,
        originating_dfi_identification: "01200012",
        originator_status_code: '1',
        batch_number: 261
      )
      batch_header.build(io)
      io.to_s.should eq(example)
      io.to_s.size.should eq(94)
    end

    it "raises an exception when the content is malformed" do
      io = IO::Memory.new
      batch_header = Nacha::BatchHeader.new(
        service_class_code: :mixed,
        company_name: "The Super MAX Acme Corporation LLC Foundation",
        company_identification: "123321121223042304023439",
        standard_entry_class: :web,
        company_entry_description: "FOR THE ONLINE PAYMENT",
        effective_entry_date: Time.utc(2022, 9, 30, 12, 0, 0),
        company_descriptive_date: Time.utc(2022, 9, 29, 12, 0, 0),
        settlement_date: 273,
        originating_dfi_identification: "89023093248001200012",
        originator_status_code: '1',
        batch_number: 261
      )

      expect_raises(Nacha::BuildError, "Could not build Batch Header") do
        batch_header.build(io)
      end

      batch_header.errors["company_identification"].should contain("is too long")
      batch_header.errors["company_name"].should contain("is too long")
      batch_header.errors["company_entry_description"].should contain("is too long")
      batch_header.errors["originating_dfi_identification"].should contain("is too long")
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
