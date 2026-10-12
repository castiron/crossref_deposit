# frozen_string_literal: true

require_relative "abstract_model"

module CrossrefDeposit
  # The party submitting the batch. Maps to a <depositor> element.
  class Depositor < AbstractModel.define(:name, :email)
    validate :name, :email, validator: :required
  end
end
