# frozen_string_literal: true

require_relative "abstract_model"

module CrossrefDeposit
  # The synchronous response to a deposit POST.
  class SubmissionReceipt < AbstractModel.define(:status_code, :body, :file_name)
    # CrossRef returns this when a user exceeds its 10,000 pending-submission cap.
    RATE_LIMIT_STATUS = 429

    # @return [Boolean] CrossRef accepted the submission
    def queued?
      status_code == 200 && body.to_s.match?(/success/i)
    end

    def rejected?
      !queued?
    end

    # @return [Boolean] throttled against the per-user pending-submission cap; resubmit later
    def rate_limited?
      status_code == RATE_LIMIT_STATUS
    end

    # @return [Symbol, nil] why the submission was not queued; nil when queued
    def failure_reason
      return nil if queued?
      return :rate_limited if rate_limited?
      return :server_error if status_code.to_i >= 500

      :client_error
    end
  end
end
