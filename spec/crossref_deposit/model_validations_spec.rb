# frozen_string_literal: true

RSpec.describe "model validation" do
  it "builds valid models without error" do
    expect { sample_book }.not_to raise_error
    expect { sample_deposit }.not_to raise_error
  end

  describe CrossrefDeposit::Book do
    it "aggregates every problem into one InvalidAttributes" do
      expect { sample_book(title: "", book_type: :banana) }
        .to raise_error(CrossrefDeposit::InvalidAttributes) do |error|
          expect(error.errors[:title]).to include("is required")
          expect(error.errors[:book_type].first).to match(/must be one of/)
          expect(error.message).to match(/title is required/)
        end
    end

    it "requires a publication_date" do
      expect { sample_book(publication_dates: []) }
        .to raise_error(CrossrefDeposit::InvalidAttributes, /publication_dates is required/)
    end

    it "requires a valid noisbn_reason when no isbns are given" do
      expect { sample_book(isbns: [], noisbn_reason: :nope) }
        .to raise_error(CrossrefDeposit::InvalidAttributes, /noisbn_reason must be one of/)
      expect { sample_book(isbns: [], noisbn_reason: :monograph) }.not_to raise_error
    end
  end

  describe CrossrefDeposit::Contributor do
    it "rejects a blank surname and unknown role/sequence, reporting all three" do
      expect { described_class.new(surname: "", contributor_role: :coauthor, sequence: :third) }
        .to raise_error(CrossrefDeposit::InvalidAttributes) { |e| expect(e.errors.size).to eq(3) }
    end
  end

  describe CrossrefDeposit::PublicationDate do
    it "enforces an integer year, month range, and media_type" do
      expect { described_class.new(year: nil) }.to raise_error(/year is required/)
      expect { described_class.new(year: 2026, month: 13) }.to raise_error(/month must be/)
      expect { described_class.new(year: 2026, media_type: :fax) }.to raise_error(/media_type must be one of/)
    end
  end

  describe CrossrefDeposit::ISBN do
    it "requires a value and a known media_type" do
      expect { described_class.new(value: "") }.to raise_error(/value is required/)
      expect { described_class.new(value: "x", media_type: :paper) }.to raise_error(/media_type must be one of/)
    end
  end

  describe CrossrefDeposit::Publisher do
    it "requires a name" do
      expect { described_class.new(name: "") }.to raise_error(/name is required/)
    end
  end

  describe CrossrefDeposit::Deposit do
    it "requires head fields and at least one item" do
      expect { sample_deposit(registrant: "") }.to raise_error(/registrant is required/)
      expect { sample_deposit(items: []) }.to raise_error(/items is required/)
    end
  end
end
