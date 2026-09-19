# frozen_string_literal: true

require_relative '../../app/errors/payroll_errors'
require_relative '../../app/services/salary_calculator'

RSpec.describe SalaryCalculator do
  describe '.base_salary' do
    it 'returns the annual salary divided by twelve' do
      expect(described_class.base_salary(120_000)).to eq(10_000.0)
    end

    it 'returns zero for a zero salary' do
      expect(described_class.base_salary(0)).to eq(0.0)
    end

    it 'rejects negative salaries with a domain error' do
      expect { described_class.base_salary(-1) }
        .to raise_error(Payroll::InvalidSalaryError, 'salary must be non-negative')
    end

    it 'rejects missing salaries with a domain error' do
      expect { described_class.base_salary(nil) }
        .to raise_error(Payroll::InvalidSalaryError, 'salary is required')
    end
  end
end
