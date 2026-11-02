# frozen_string_literal: true

require_relative "../errors"

class AbstractModel < Data
  class << self
    attr_reader :default_values

    def defaults(**defaults)
      @default_values = defaults
    end

    def validate(*attrs, validator:, **options)
      @validations ||= {}
      attrs.each do |attr|
        key = attr.to_sym
        @validations[key] ||= []
        @validations[key] << Validator.new(validator, attr, **options)
      end
    end

    # @raise [CrossrefDeposit::InvalidAttributes] when any validator fails
    def validate!(instance)
      errors = {}
      @validations&.each do |attr, validators|
        validators.each do |validator|
          result = validator.(instance)
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

  class Validator
    PREBUILT_VALIDATORS = {
      required: [
        ->(val) { "is required" if val.nil? || (val.respond_to?(:empty?) && val.empty?) },
        { allow_nil: false }
      ],
      numeric: ->(val) { "must be numeric" unless val.to_i.to_s == val.to_s },
      included: ->(val, set:) { "must be one of #{set.join(", ")}" unless set.include? val }
    }.freeze

    DEFAULT_OPTIONS = {
      allow_nil: true
    }.freeze

    # Other kwargs are passed to the validator proc
    VALIDATOR_OPTIONS = %i[allow_nil if].freeze

    def initialize(proc_or_name, attr, **options)
      build_validator_proc(proc_or_name)
      @attr = attr
      @options = DEFAULT_OPTIONS.merge(@prebuilt_options).merge(options)
      @validator_options = @options.slice(*VALIDATOR_OPTIONS)
      @proc_options = @options.except(*VALIDATOR_OPTIONS)
    end

    def call(instance)
      return if skip?(instance)

      value = instance.send(@attr)
      return if @validator_options[:allow_nil] && value.nil?

      @proc.call(value, **@proc_options)
    end

    def build_validator_proc(thing)
      @proc, @prebuilt_options = case thing
      when Proc
                                   [ thing, {} ]
      when Symbol
                                   lookup_prebuilt(thing)
      end
    end

    def lookup_prebuilt(name)
      prebuilt = PREBUILT_VALIDATORS[name.to_sym]
      raise(ArgumentError, "prebuilt validator #{name} not found") unless prebuilt

      prebuilt.is_a?(Array) ? prebuilt : [ prebuilt, {} ]
    end

    def skip?(instance)
      return false unless @validator_options[:if]

      !instance.instance_exec(&@validator_options[:if])
    end
  end
end
