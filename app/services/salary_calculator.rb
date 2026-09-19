# frozen_string_literal: true

class SalaryCalculator
  MONTHS_IN_YEAR = 12.0

  class << self
    def base_salary(annual_salary)
      salary = validate_salary!(annual_salary)
      salary / MONTHS_IN_YEAR
    end

    def net_pay(annual_salary, bonus: 0, tax_service: TaxDeductionService)
      salary = validate_salary!(annual_salary)
      bonus_amount = validate_non_negative!(bonus, 'bonus')
      taxable_income = salary + bonus_amount
      taxable_income - tax_service.calculate_for(taxable_income)[:total_tax]
    end

    def bonus_tier(annual_salary)
      salary = validate_salary!(annual_salary)

      case salary
      when 0...50_000 then :none
      when 50_000...100_000 then :standard
      when 100_000...150_000 then :premium
      else :executive
      end
    end

    private

    def validate_salary!(value)
      validate_non_negative!(value, 'salary')
    end

    def validate_non_negative!(value, name)
      number = Float(value)
      raise ArgumentError, "#{name} must be non-negative" if number.negative?

      number
    rescue TypeError, ArgumentError
      raise ArgumentError, "#{name} must be a number"
    end
  end
end
