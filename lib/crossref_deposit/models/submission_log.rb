# frozen_string_literal: true

require "nokogiri"

require_relative "abstract_model"

module CrossrefDeposit
  # A parsed CrossRef processing log (<doi_batch_diagnostic>)
  class SubmissionLog < AbstractModel.define(:xml, :status, :submission_id, :batch_id, :records,
                                             :record_count, :success_count, :warning_count, :failure_count)
    # One <record_diagnostic> entry.
    Record = Data.define(:doi, :status, :message) do
      def success?
        status.to_s.casecmp?("success")
      end
    end

    class << self
      # @param raw [String] a <doi_batch_diagnostic> response body
      # @return [SubmissionLog]
      def parse(raw)
        doc = Nokogiri::XML(raw)
        batch_data = doc.at_xpath("//batch_data")
        new(
          xml: raw,
          status: doc.at_xpath("//doi_batch_diagnostic")&.[]("status"),
          submission_id: doc.at_xpath("//submission_id")&.text,
          batch_id: doc.at_xpath("//batch_id")&.text,
          records: doc.xpath("//record_diagnostic").map do |node|
            Record.new(
              doi: node.at_xpath("doi")&.text,
              status: node["status"],
              message: node.at_xpath("msg")&.text
            )
          end,
          record_count: batch_data&.at_xpath("record_count")&.text.to_i,
          success_count: batch_data&.at_xpath("success_count")&.text.to_i,
          warning_count: batch_data&.at_xpath("warning_count")&.text.to_i,
          failure_count: batch_data&.at_xpath("failure_count")&.text.to_i
        )
      end
    end

    def completed?
      status.to_s.casecmp?("completed")
    end

    # @return [Boolean] every record registered and none failed
    def success?
      completed? && failure_count.zero? && records.any? && records.all?(&:success?)
    end

    # @return [Array<Record>]
    def failures
      records.reject(&:success?)
    end
  end
end
