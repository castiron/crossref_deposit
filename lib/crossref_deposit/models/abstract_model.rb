# frozen_string_literal: true

require_relative "../errors"

class AbstractModel < Data
  BUILT_IN_VALIDATORS = {
    required: ->(val) { "is required" if val.nil? || (val.respond_to?(:empty?) && val.empty?) },
    numeric: ->(val) { "must be numeric" unless val.to_i.to_s == val.to_s }
  }.freeze

  class << self
    attr_reader :default_values

    def defaults(**defaults)
      @default_values = defaults
    end

    def validate(*attrs, validator:)
      @validations ||= {}
      resolved = validator.is_a?(Symbol) ? (BUILT_IN_VALIDATORS[validator] || validator) : validator
      attrs.each { |attr| (@validations[attr.to_sym] ||= []) << resolved }
    end

    # @raise [CrossrefDeposit::InvalidAttributes] when any validator fails
    def validate!(instance)
      errors = {}
      @validations&.each do |attr, validators|
        validators.each do |validator|
          result = validator.is_a?(Proc) ? validator.call(instance.send(attr)) : instance.send(validator)
          (errors[attr] ||= []) << result if result
        end
      end

      raise ::CrossrefDeposit::InvalidAttributes, errors if errors.any?
    end
  end

  def initialize(**kwargs)
    super(**(self.class.default_values || {}).merge(kwargs))
    self.class.validate! self
  end
end
