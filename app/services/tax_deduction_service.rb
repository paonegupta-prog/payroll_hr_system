# frozen_string_literal: true

require_relative '../errors/payroll_errors'

class TaxDeductionService
  TAX_BRACKETS = [
    [50_000.0, 0.10],
    [100_000.0, 0.15],
    [150_000.0, 0.20],
    [250_000.0, 0.25],
    [Float::INFINITY, 0.30]
  ].freeze

  class << self
    def calculate_for(annual_income)
      income = validate_income!(annual_income)
      tax = progressive_tax(income)
      {
        total_tax: tax.round(2),
        monthly_tax: (tax / 12.0).round(2),
        effective_rate: income.zero? ? 0.0 : ((tax / income) * 100).round(2)
      }
    end

    def total_tax(incomes)
      raise Payroll::InvalidIncomeError, 'incomes are required' if incomes.nil?

      incomes.sum { |income| calculate_for(income)[:total_tax] }
    end

    private

    def validate_income!(value)
      raise Payroll::InvalidIncomeError, 'income is required' if value.nil?

      income = Float(value)
      raise Payroll::InvalidIncomeError, 'income must be non-negative' if income.negative?

      income
    rescue TypeError, ArgumentError => error
      raise error if error.is_a?(Payroll::InvalidIncomeError)

      raise Payroll::InvalidIncomeError, 'income must be numeric'
    end

    def progressive_tax(income)
      lower_bound = 0.0
      TAX_BRACKETS.sum do |upper_bound, rate|
        taxable = [income - lower_bound, upper_bound - lower_bound].min
        lower_bound = upper_bound
        taxable.positive? ? taxable * rate : 0.0
      end
    end
  end
end
