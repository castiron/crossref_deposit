# frozen_string_literal: true

require_relative "abstract_model"

module CrossrefDeposit
  # A deposit batch: the <doi_batch> head plus one or more book items.
  class Deposit < AbstractModel.define(:doi_batch_id, :depositor, :registrant, :items, :timestamp)
    defaults timestamp: Time.now.strftime("%Y%m%d%H%M%S")

    validate :doi_batch_id, :depositor, :registrant, :items, :timestamp, validator: :required

    # @return [String] the doi_batch XML
    def to_xml
      Builder.new(self).to_xml
    end

    # @param validator [#validate] defaults to the shared {CrossrefDeposit.validator}
    # @return [Array<String>] schema error messages; empty when valid
    def validate(validator: CrossrefDeposit.validator)
      validator.validate(to_xml)
    end

    def valid?(validator: CrossrefDeposit.validator)
      validate(validator:).empty?
    end

    # @raise [ValidationError] when the generated XML is invalid
    # @return [self]
    def validate!(validator: CrossrefDeposit.validator)
      errors = validate(validator:)
      raise ValidationError, { xml: errors } unless errors.empty?

      self
    end
  end
end
