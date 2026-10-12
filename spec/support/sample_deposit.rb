# frozen_string_literal: true

# Builders for a complete, schema-valid deposit, overridable per example.
module SampleDeposit
  def sample_book(**overrides)
    defaults = {
      doi: "10.1525/example.1",
      resource_url: "https://example.com/books/example",
      title: "An Example Monograph",
      subtitle: "A Subtitle",
      contributors: [
        CrossrefDeposit::Contributor.new(surname: "Doe", given_name: "Jane",
                                         sequence: :first, contributor_role: :author),
        CrossrefDeposit::Contributor.new(surname: "Roe", given_name: "Richard",
                                         sequence: :additional, contributor_role: :editor)
      ],
      edition_number: 1,
      publication_dates: [
        CrossrefDeposit::PublicationDate.new(year: 2026, month: 3, day: 15, media_type: :online)
      ],
      isbns: [
        CrossrefDeposit::ISBN.new(value: "9780520000000", media_type: :electronic)
      ],
      publisher: CrossrefDeposit::Publisher.new(name: "Example Press",
                                                place: "Exampleville, OR")
    }
    CrossrefDeposit::Book.new(**defaults.merge(overrides))
  end

  def sample_deposit(items: nil, **overrides)
    defaults = {
      doi_batch_id: "example-20260307-0001",
      depositor: CrossrefDeposit::Depositor.new(name: "Example Press", email: "doi@example.com"),
      registrant: "Example Press",
      items: items || [ sample_book ]
    }
    CrossrefDeposit::Deposit.new(**defaults.merge(overrides))
  end
end

RSpec.configure { |config| config.include SampleDeposit }
