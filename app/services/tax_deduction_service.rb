# frozen_string_literal: true

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
      income = Float(annual_income)
      raise ArgumentError, 'income must be non-negative' if income.negative?

      tax = progressive_tax(income)
      {
        total_tax: tax.round(2),
        monthly_tax: (tax / 12.0).round(2),
        effective_rate: income.zero? ? 0.0 : ((tax / income) * 100).round(2)
      }
    rescue TypeError, ArgumentError => error
      raise error if error.message == 'income must be non-negative'

      raise ArgumentError, 'income must be a number'
    end

    def total_tax(incomes)
      incomes.sum { |income| calculate_for(income)[:total_tax] }
    end

    private

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
