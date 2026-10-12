# frozen_string_literal: true

RSpec.describe CrossrefDeposit::Client do
  let(:client) do
    described_class.new(login_id: "example/role", login_passwd: "secret", environment: :test)
  end

  describe "#submit" do
    let(:endpoint) { "https://test.crossref.org/servlet/deposit" }

    it "posts a multipart deposit and returns a queued receipt" do
      stub = stub_request(:post, endpoint)
        .to_return(status: 200, body: "<html><body><h2>SUCCESS</h2></body></html>")

      receipt = client.submit("<doi_batch/>", file_name: "batch-1.xml")

      expect(receipt).to be_queued
      expect(receipt.file_name).to eq("batch-1.xml")
      expect(stub.with { |req|
        body = req.body
        body.include?("doMDUpload") && body.include?("example/role") &&
          body.include?("batch-1.xml") && body.include?("<doi_batch/>")
      }).to have_been_requested
    end

    it "marks a non-success response as rejected" do
      stub_request(:post, endpoint).to_return(status: 401, body: "Unauthorized")
      expect(client.submit("<doi_batch/>", file_name: "batch-1.xml")).to be_rejected
    end
  end

  describe "#fetch_result" do
    let(:endpoint) { "https://test.crossref.org/servlet/submissionDownload" }

    it "posts the result query and parses the log" do
      body = File.read(File.join(__dir__, "..", "fixtures", "result_success.xml"))
      stub = stub_request(:post, endpoint).to_return(status: 200, body: body)

      log = client.fetch_result(file_name: "batch-1.xml")

      expect(log).to be_success
      expect(stub.with { |req|
        req.body.include?("type=result") || req.body.include?("result")
      }).to have_been_requested
    end
  end

  it "rejects an unknown environment" do
    expect {
      described_class.new(login_id: "x", login_passwd: "y", environment: :staging)
    }.to raise_error(KeyError)
  end
end
