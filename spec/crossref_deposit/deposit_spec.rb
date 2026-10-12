# frozen_string_literal: true

RSpec.describe CrossrefDeposit::Deposit do
  it "defaults the timestamp to a 14-digit stamp" do
    expect(sample_deposit.timestamp).to match(/\A\d{14}\z/)
  end

  it "exposes the items it was given" do
    expect(sample_deposit(items: [ sample_book ]).items.size).to eq(1)
    expect(sample_deposit(items: [ sample_book, sample_book ]).items.size).to eq(2)
  end

  describe "#valid? / #validate!" do
    it "is valid for a complete deposit" do
      expect(sample_deposit).to be_valid
      expect(sample_deposit.validate!).to be_a(described_class)
    end

    it "delegates to an injected validator" do
      fake = Class.new { def validate(_xml) = [ "boom" ] }.new
      expect(sample_deposit.validate(validator: fake)).to eq([ "boom" ])
    end

    it "raises ValidationError when the schema validator reports errors" do
      fake = Class.new { def validate(_xml) = [ "bad element" ] }.new
      expect { sample_deposit.validate!(validator: fake) }.to raise_error(CrossrefDeposit::ValidationError) do |error|
        expect(error.errors).to eq({ xml: [ "bad element" ] })
      end
    end
  end
end
