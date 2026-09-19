# frozen_string_literal: true

require_relative '../../app/services/tax_deduction_service'
require_relative '../../app/services/salary_calculator'

RSpec.describe SalaryCalculator do
  describe '.base_salary' do
    it 'returns the annual salary divided by twelve' do
      expect(described_class.base_salary(120_000)).to eq(10_000.0)
    end

    it 'returns zero for a zero salary' do
      expect(described_class.base_salary(0)).to eq(0.0)
    end

    it 'rejects negative salaries' do
      expect { described_class.base_salary(-1) }.to raise_error(ArgumentError, 'salary must be non-negative')
    end
  end

  describe '.bonus_tier' do
    it 'assigns tiers based on annual salary' do
      expect(described_class.bonus_tier(125_000)).to eq(:premium)
    end
  end

  describe '.net_pay' do
    it 'subtracts progressive tax from salary and bonus' do
      expect(described_class.net_pay(50_000, bonus: 0)).to eq(45_000.0)
    end
  end
end
