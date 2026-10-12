# frozen_string_literal: true

RSpec.describe CrossrefDeposit::Validator do
  it "accepts a well-formed deposit (offline, against the bundled schema)" do
    expect(described_class.new.validate(sample_deposit.to_xml)).to be_empty
  end

  it "validates a book with noisbn" do
    xml = sample_deposit(items: [ sample_book(isbns: []) ]).to_xml
    expect(described_class.new.validate(xml)).to be_empty
  end

  it "reports schema violations" do
    broken = sample_deposit.to_xml.sub("<titles>", "<nonsense/><titles>")
    errors = described_class.new.validate(broken)
    expect(errors).not_to be_empty
  end

  it "is shared via the default validator so the schema compiles once" do
    expect(CrossrefDeposit.validator).to be(CrossrefDeposit.validator)
  end
end
