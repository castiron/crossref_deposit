# frozen_string_literal: true

require_relative "abstract_model"

module CrossrefDeposit
  # The synchronous response to a deposit POST.
  class SubmissionReceipt < AbstractModel.define(:status_code, :body, :file_name)
    # @return [Boolean] CrossRef accepted the submission
    def queued?
      status_code == 200 && body.to_s.match?(/success/i)
    end

    def rejected?
      !queued?
    end
  end
end
