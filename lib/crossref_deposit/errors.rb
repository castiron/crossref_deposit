# frozen_string_literal: true

module CrossrefDeposit
  class Error < StandardError; end

  # Raised by {Deposit#validate!} when the generated XML fails schema validation.
  class ValidationError < Error
    # @return [Hash{Symbol => Array<String>}] schema error messages keyed by source
    attr_reader :errors

    def initialize(errors)
      @errors = errors
      message = errors.map do |key, value|
        "Invalid #{key} - #{value.join(", ")}"
      end.join("; ")
      super("CrossRef deposit XML failed schema validation:\n#{message}")
    end
  end

  # Raised when a model is constructed with invalid attributes.
  class InvalidAttributes < Error
    # @return [Hash{Symbol => Array<String>}] error messages keyed by attribute
    attr_reader :errors

    def initialize(errors)
      @errors = errors
      message = errors.map do |key, value|
        "#{key} #{value.join(", ")}"
      end.join("; ")
      super(message)
    end
  end
end
