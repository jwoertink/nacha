module Nacha
  class BaseError < Exception
  end

  class ParserError < BaseError
  end

  class BuildError < BaseError
  end
end
