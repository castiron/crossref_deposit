# frozen_string_literal: true

RSpec.describe CrossrefDeposit::SubmissionLog do
  def fixture(name)
    File.read(File.join(__dir__, "..", "fixtures", name))
  end

  context "with a successful log" do
    subject(:log) { described_class.parse(fixture("result_success.xml")) }

    it "parses batch metadata and counts" do
      expect(log).to be_completed
      expect(log.submission_id).to eq("1234567890")
      expect(log.batch_id).to eq("example-20260307-0001")
      expect(log.record_count).to eq(1)
      expect(log.success_count).to eq(1)
      expect(log.failure_count).to eq(0)
    end

    it "is a success with no failures" do
      expect(log).to be_success
      expect(log.failures).to be_empty
      expect(log.records.first.doi).to eq("10.1525/example.1")
    end
  end

  context "with a failed log" do
    subject(:log) { described_class.parse(fixture("result_failure.xml")) }

    it "is not a success and exposes the failing records" do
      expect(log).not_to be_success
      expect(log.failure_count).to eq(1)
      expect(log.failures.map(&:doi)).to eq([ "10.1525/example.2" ])
      expect(log.failures.first.message).to match(/version/)
    end
  end
end
