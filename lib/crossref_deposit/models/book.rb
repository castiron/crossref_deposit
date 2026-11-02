# frozen_string_literal: true

require_relative "abstract_model"

module CrossrefDeposit
  # A book to register. Maps to a <book>/<book_metadata> element.
  class Book < AbstractModel.define(
    :doi, :resource_url, :title, :subtitle, :book_type, :language,
    :contributors, :edition_number, :publication_dates, :isbns, :publisher, :noisbn_reason
  )
    BOOK_TYPES = %i[monograph edited_book reference other].freeze
    NOISBN_REASONS = %i[archive_volume monograph simple_series].freeze

    defaults subtitle: nil,
             book_type: :monograph,
             language: "en",
             contributors: [],
             edition_number: nil,
             publication_dates: [],
             isbns: [],
             noisbn_reason: :monograph

    validate :doi, :resource_url, :title, :publisher, :publication_dates, validator: :required
    validate :edition_number, validator: :numeric
    validate :book_type, validator: :included, set: BOOK_TYPES
    validate :noisbn_reason, validator: :included, set: NOISBN_REASONS, if: -> { isbns.none? }
  end
end
