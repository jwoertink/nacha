require "../spec_helper"

include DetailHelper

describe Nacha::File do
  describe "generate" do
    it "builds a full nacha formatted file" do
      # Avoid issues with ameba and trailing spaces
      example = [
        "101 012345678 8723161272212071417A094101Bank of Specialty      My Company Name                ",
        "5220My Company                          1234567890WEBPAY OUT   221207221207   1071000500000001",
        "62210264791931945123488995   0000062432418            Billy Bonka             0000000000000001",
        "622318092165493805838128300  0000035249419            Milly Monka             0000000000000002",
        "822000000200420740070000000000000000000976811234567890                         071000500000001",
        "9000001000001000000020042074007000000000000000000097681                                       ",
        "9999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999",
        "9999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999",
        "9999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999",
        "9999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999",
      ].join("\n")

      # 10 rows plus 9 linebreaks
      example_size = Nacha::File::RECORD_SIZE * 10 + 9
      example.bytesize.should eq(example_size)

      current_time = Time.utc(2022, 12, 7, 14, 17, 0)

      file_header = Nacha::FileHeader.new(
        immediate_destination: "012345678",
        immediate_origin: "872316127",
        immediate_destination_name: "Bank of Specialty",
        immediate_origin_name: "My Company Name",
        file_creation_date: current_time,
        file_creation_time: current_time,
      )
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
      entry1 = Nacha::EntryDetail.new(
        transaction_code: :checking_credit,
        dfi_routing_number: "102647919",
        dfi_account_number: "31945123488995",
        amount: 62432, # $624.32
        individual_identification_number: "418",
        individual_name: "Billy Bonka",
        trace_number: "1"
      )
      entry2 = Nacha::EntryDetail.new(
        transaction_code: :checking_credit,
        dfi_routing_number: "318092165",
        dfi_account_number: "493805838128300",
        amount: 35249, # $352.49
        individual_identification_number: "419",
        individual_name: "Milly Monka",
        trace_number: "2"
      )
      batch = Nacha::Batch.new(
        header: batch_header,
        entries: [entry1, entry2] of Nacha::EntryDetail
      )

      file = Nacha::File.new(header: file_header, batches: [batch])
      file.generate.should eq(example)
    end

    it "handles the overflow past 10 lines" do
      current_time = Time.utc(2022, 12, 7, 14, 17, 0)

      file_header = Nacha::FileHeader.new(
        immediate_destination: "012345678",
        immediate_origin: "872316127",
        immediate_destination_name: "Bank of Specialty",
        immediate_origin_name: "My Company Name",
        file_creation_date: current_time,
        file_creation_time: current_time,
      )
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

      entries = [] of Nacha::EntryDetail

      7.times do |_i|
        entries << build_entry_detail(dfi_routing_number: "111111111", amount: 10000)
      end

      batch = Nacha::Batch.new(
        header: batch_header,
        entries: entries,
      )

      file = Nacha::File.new(header: file_header, batches: [batch])
      nacha = file.generate
      parsed = Nacha::Parser.new.parse(nacha)
      nacha.split('\n').size.should eq(20)
      parsed.control.block_count.should eq(2)
      parsed.control.total_credit_amount.should eq(70000)
      parsed.control.entry_hash.should eq(77777777_i64)
    end
  end
end
