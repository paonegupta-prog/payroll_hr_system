# frozen_string_literal: true

require_relative '../../app/services/tax_deduction_service'

RSpec.describe TaxDeductionService do
  it 'calculates progressive tax across brackets' do
    expect(described_class.calculate_for(150_000)[:total_tax]).to eq(22_500.0)
  end

  it 'returns zero tax for zero income' do
    expect(described_class.calculate_for(0)[:total_tax]).to eq(0.0)
  end

  it 'rejects negative income' do
    expect { described_class.calculate_for(-1) }.to raise_error(ArgumentError, 'income must be non-negative')
  end
end
