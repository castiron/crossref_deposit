# frozen_string_literal: true

require_relative "abstract_model"

module CrossrefDeposit
  # A contributor to a book. Maps to a <person_name> element.
  class Contributor < AbstractModel.define(:surname, :given_name, :sequence, :contributor_role)
    SEQUENCES = %i[first additional].freeze
    ROLES = %i[
      author editor chair reviewer review-assistant stats-reviewer
      reviewer-external reader translator corresponding-author other
    ].freeze

    defaults given_name: nil, sequence: :first, contributor_role: :author

    validate :surname, validator: :required
    validate :sequence, validator: :included, set: SEQUENCES
    validate :contributor_role, validator: :included, set: ROLES
  end
end
