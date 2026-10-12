# frozen_string_literal: true

require "crossref_deposit/version"

# Build, validate, and submit CrossRef deposit (doi_batch) XML to register DOIs.
module CrossrefDeposit
  DEFAULT_ENVIRONMENT = :production
  ENVIRONMENTS = %i[production test]
  SCHEMA_VERSION = "5.5.0"
  SCHEMA_ROOT = File.expand_path("../vendor/schema/crossref#{SCHEMA_VERSION}", __dir__)
  SCHEMA_PATH = File.join(SCHEMA_ROOT, "crossref#{SCHEMA_VERSION}.xsd")

  class << self
    def set_environment(env)
      raise ArgumentError, "invalid environment: #{env}" unless ENVIRONMENTS.include?(env.to_sym)

      @environment = env.to_sym
    end

    # @return [Symbol]
    def environment
      @environment || DEFAULT_ENVIRONMENT
    end

    # Use a different validator
    # CrossrefDeposit only ships with one, but maybe someone wants their own.
    def set_validator(validator_class)
      @validator_class = validator_class
    end

    # Memoize so we only need to compile the schema once
    # @return [Validator]
    def validator
      @validator ||= (@validator_class || default_validator_class).new
    end

    # Shared validator, so the schema compiles once per process.
    # @return [Validator]
    def default_validator_class
      Validator
    end
  end
end

require "crossref_deposit/errors"
require "crossref_deposit/models/depositor"
require "crossref_deposit/models/contributor"
require "crossref_deposit/models/publication_date"
require "crossref_deposit/models/isbn"
require "crossref_deposit/models/publisher"
require "crossref_deposit/models/book"
require "crossref_deposit/models/submission_receipt"
require "crossref_deposit/models/submission_log"
require "crossref_deposit/models/deposit"
require "crossref_deposit/services/builder"
require "crossref_deposit/services/validator"
require "crossref_deposit/services/client"
