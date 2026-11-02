# frozen_string_literal: true

require_relative "abstract_model"

module CrossrefDeposit
  # An ISBN. Maps to an <isbn> element.
  class ISBN < AbstractModel.define(:value, :media_type)
    MEDIA_TYPES = %i[print electronic].freeze

    defaults media_type: nil

    validate :value, validator: :required
    validate :media_type, validator: :included, set: MEDIA_TYPES
  end
end
