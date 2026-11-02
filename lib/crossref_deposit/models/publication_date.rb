# frozen_string_literal: true

require_relative "abstract_model"

module CrossrefDeposit
  # A publication date. Maps to a <publication_date> element.
  class PublicationDate < AbstractModel.define(:year, :month, :day, :media_type)
    MEDIA_TYPES = %i[online print other].freeze

    defaults month: nil, day: nil, media_type: nil

    validate :year, validator: :required
    validate :year, validator: :numeric
    validate :month, validator: :included, set: (1..12).to_a
    validate :day, validator: :included, set: (1..31).to_a
    validate :media_type, validator: :included, set: MEDIA_TYPES
  end
end
