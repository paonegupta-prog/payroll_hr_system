# frozen_string_literal: true

module Payroll
  class DomainError < StandardError; end

  class InvalidSalaryError < DomainError; end
  class InvalidIncomeError < DomainError; end
  class InvalidPayrollParameterError < DomainError; end
end
