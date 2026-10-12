# frozen_string_literal: true

require "stringio"
require "faraday"
require "faraday/multipart"

module CrossrefDeposit
  # Submits deposit XML to CrossRef and fetches submission results over the
  # standard HTTPS deposit interface.
  class Client
    DEPOSIT_ENDPOINTS = {
      production: "https://doi.crossref.org/servlet/deposit",
      test: "https://test.crossref.org/servlet/deposit"
    }.freeze

    RESULT_ENDPOINTS = {
      production: "https://doi.crossref.org/servlet/submissionDownload",
      test: "https://test.crossref.org/servlet/submissionDownload"
    }.freeze

    DEFAULT_TIMEOUT = 60

    attr_reader :environment

    # @param environment [Symbol] :production or :test
    def initialize(login_id:, login_passwd:, environment: CrossrefDeposit.environment, timeout: DEFAULT_TIMEOUT, connection: nil)
      @login_id = login_id
      @login_passwd = login_passwd
      @environment = environment.to_sym
      DEPOSIT_ENDPOINTS.fetch(@environment)
      @timeout = timeout
      @connection = connection || build_connection
    end

    # Queue a deposit for asynchronous processing.
    # @param file_name [String] unique tracking name for the submission
    # @return [SubmissionReceipt]
    def submit(xml, file_name:)
      response = @connection.post(DEPOSIT_ENDPOINTS.fetch(environment)) do |req|
        req.body = {
          operation: "doMDUpload",
          login_id: @login_id,
          login_passwd: @login_passwd,
          fname: Faraday::Multipart::FilePart.new(StringIO.new(xml), "application/xml", file_name)
        }
      end
      SubmissionReceipt.new(status_code: response.status, body: response.body, file_name: file_name)
    end

    # Retrieve the processing log for a prior submission.
    # @return [SubmissionLog]
    def fetch_result(file_name:)
      response = @connection.post(RESULT_ENDPOINTS.fetch(environment)) do |req|
        req.body = {
          usr: @login_id,
          pwd: @login_passwd,
          file_name: file_name,
          type: "result"
        }
      end
      SubmissionLog.parse(response.body)
    end

    private

    def build_connection
      Faraday.new do |faraday|
        faraday.request :multipart
        faraday.request :url_encoded
        faraday.options.timeout = @timeout
        faraday.adapter Faraday.default_adapter
      end
    end
  end
end
