# frozen_string_literal: true

require_relative "abstract_model"

module CrossrefDeposit
  # A publication date. Maps to a <publication_date> element.
  class PublicationDate < AbstractModel.define(:year, :month, :day, :media_type)
    MEDIA_TYPES = %i[online print other].freeze

    defaults month: nil, day: nil, media_type: nil

    validate :year, validator: :required
    validate :year, validator: :numeric
    validate :month, validator: ->(val) { "must be between 1 and 12" unless val.nil? || (1..12).include?(val) }
    validate :day, validator: ->(val) { "must be between 1 and 31" unless val.nil? || (1..31).include?(val) }
    validate :media_type, validator: ->(val) { "must be one of #{MEDIA_TYPES.join(", ")}" unless MEDIA_TYPES.include?(val) }
  end
end
