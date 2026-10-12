# frozen_string_literal: true

RSpec.describe CrossrefDeposit::SubmissionReceipt do
  def receipt(status_code, body = "")
    described_class.new(status_code: status_code, body: body, file_name: "batch-1.xml")
  end

  it "is queued on a 200 success body" do
    subject = receipt(200, "<html><h2>SUCCESS</h2></html>")
    expect(subject).to be_queued
    expect(subject).not_to be_rejected
    expect(subject.failure_reason).to be_nil
  end

  it "flags a 429 as rate limited" do
    subject = receipt(429, "too many pending submissions")
    expect(subject).to be_rejected
    expect(subject).to be_rate_limited
    expect(subject.failure_reason).to eq(:rate_limited)
  end

  it "distinguishes server from client failures" do
    expect(receipt(503).failure_reason).to eq(:server_error)
    expect(receipt(401).failure_reason).to eq(:client_error)
    expect(receipt(200, "nope").failure_reason).to eq(:client_error)
  end
end
