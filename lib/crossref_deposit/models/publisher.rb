# frozen_string_literal: true

require_relative "abstract_model"

module CrossrefDeposit
  # A publisher. Maps to a <publisher> element.
  class Publisher < AbstractModel.define(:name, :place)
    defaults place: nil

    validate :name, validator: :required
  end
end
