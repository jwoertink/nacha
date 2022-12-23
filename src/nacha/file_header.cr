module Nacha
  # This record includes your company name and
  # company number. It also designates the immediate destination (LaSalle Bank
  # N.A. or Standard Federal Bank) of the entries contained within the file.
  class FileHeader
    include BuildableRecord
    include ParsableRecord

    TYPE_CODE     = 1 # Identifies this is the FileHeader
    PRIORITY_CODE = 1 # lower number is higher priority (but only 01 is used)

    getter immediate_destination : String       # The Primary bank Routing number
    getter immediate_origin : String            # The Primary company EIN or ABN AMRO number
    getter immediate_destination_name : String  # The Primary bank name
    getter immediate_origin_name : String       # The Primary company's name
    getter file_creation_date : Time = Time.utc # File creation date Formatted as YYMMDD
    getter file_creation_time : Time = Time.utc # File creation time Formatted as HHMM
    getter file_id_modifier : Char = 'A'        # Each file submitted in the same day must update this to the next consecutive letter, then 0-9
    getter reference_code : String? = nil

    def initialize(
      @immediate_destination : String,
      @immediate_origin : String,
      @immediate_destination_name : String,
      @immediate_origin_name : String,
      @file_creation_date : Time = Time.utc,
      @file_creation_time : Time = Time.utc,
      @file_id_modifier : Char = 'A',
      @reference_code : String? = nil
    )
    end

    def self.raise_parse_error(name : String, value : String)
      ParsableRecord.raise_parse_failed_error(name, value, "File Header")
    end

    def self.parse(input : String) : self
      if input.bytesize == Nacha::File::RECORD_SIZE
        type_code = input[0].to_s
        type_code == TYPE_CODE.to_s || raise_parse_error("Type Code", type_code)

        priority_code = input[1..2]
        priority_code == PRIORITY_CODE.to_s.rjust(2, '0') || raise_parse_error("Priority Code", priority_code)

        immediate_destination = input[3..12]
        immediate_origin = input[13..22]

        file_creation_date = input[23..28]
        file_creation_date.match(/\d{6}/) || raise_parse_error("File Creation Date", file_creation_date)

        file_creation_time = input[29..32]
        file_creation_time.match(/\d{4}/) || raise_parse_error("File Creation Time", file_creation_time)

        file_id_modifier = input[33].to_s
        file_id_modifier.match(/[a-zA-Z0-9]/) || raise_parse_error("File ID Modifier", file_id_modifier)

        record_size = input[34..36]
        record_size == Nacha::File::RECORD_SIZE.to_s.rjust(3, '0') || raise_parse_error("Record Size", record_size)

        blocking_factor = input[37..38]
        blocking_factor == Nacha::File::BLOCKING_FACTOR.to_s || raise_parse_error("Blocking Factor", blocking_factor)

        format_code = input[39].to_s
        format_code == Nacha::File::FORMAT_CODE.to_s || raise_parse_error("Format Code", format_code)

        immediate_destination_name = input[40..62]
        immediate_origin_name = input[63..85]
        reference_code = input[86..93]

        new(
          immediate_destination: immediate_destination.strip,
          immediate_origin: immediate_origin.strip,
          immediate_destination_name: immediate_destination_name.strip,
          immediate_origin_name: immediate_origin_name.strip,
          file_creation_date: Time.parse_utc(file_creation_date, "%y%m%d"),
          file_creation_time: Time.parse_utc(file_creation_time, "%H%M"),
          file_id_modifier: file_id_modifier[0],
          reference_code: reference_code.strip.presence,
        )
      else
        raise_parse_error("Record Length", input.bytesize.to_s)
      end
    end

    def build(io : IO) : IO
      io << TYPE_CODE.to_s
      io << PRIORITY_CODE.to_s.rjust(2, '0')
      io << @immediate_destination.rjust(10, ' ')
      io << @immediate_origin.rjust(10, ' ')
      io << @file_creation_date.to_s("%y%m%d")
      io << @file_creation_time.to_s("%H%M")
      io << @file_id_modifier.to_s
      io << Nacha::File::RECORD_SIZE.to_s.rjust(3, '0')
      io << Nacha::File::BLOCKING_FACTOR.to_s
      io << Nacha::File::FORMAT_CODE.to_s
      io << @immediate_destination_name[0..22].ljust(23, ' ')
      io << @immediate_origin_name[0..22].ljust(23, ' ')
      io << @reference_code.to_s.ljust(8, ' ')
      io
    end
  end
end
