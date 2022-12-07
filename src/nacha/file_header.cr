module Nacha
  # This record includes your company name and
  # company number. It also designates the immediate destination (LaSalle Bank
  # N.A. or Standard Federal Bank) of the entries contained within the file.
  class FileHeader
    include BuildableRecord

    TYPE_CODE = 1 # Identifies this is the FileHeader
    PRIORITY_CODE = 1 # lower number is higher priority (but only 01 is used)

    def initialize(
      @immediate_destination : String, # The Primary bank Routing number
      @immediate_origin : String, # The Primary company EIN or ABN AMRO number
      @immediate_destination_name : String, # The Primary bank name
      @immediate_origin_name : String, # The Primary company's name
      @file_creation_date : Time = Time.utc, # File creation date Formatted as YYMMDD
      @file_creation_time : Time = Time.utc, # File creation time Formatted as HHMM
      @file_id_modifier : Char = 'A', # Each file submitted in the same day must update this to the next consecutive letter, then 0-9
      @record_size : Int32 = 94, # The number of bytes per record row
      @blocking_factor : String = "10", # wat
      @format_code : String = "1", # Placeholder for future other formats
      @reference_code : String? = nil # Used for your own internal accounting
    )
    end

    def build(io : IO) : IO
      io << TYPE_CODE.to_s
      io << PRIORITY_CODE.to_s.rjust(2, '0')
      io << @immediate_destination.rjust(10, ' ')
      io << @immediate_origin.rjust(10, ' ')
      io << @file_creation_date.to_s("%y%m%d")
      io << @file_creation_time.to_s("%H%M")
      io << @file_id_modifier.to_s
      io << @record_size.to_s.rjust(3, '0')
      io << @blocking_factor
      io << @format_code
      io << @immediate_destination_name[0..22].ljust(23, ' ')
      io << @immediate_origin_name[0..22].ljust(23, ' ')
      io << @reference_code.to_s.ljust(8, ' ')
      io
    end
  end
end
