# frozen_string_literal: true

require_relative '../../app/services/payroll_report_generator'
require_relative '../../app/services/tax_deduction_service'

RSpec.describe PayrollReportGenerator do
  Employee = Struct.new(:annual_salary, :bonus, :department, :designation, :pay_band, :active, keyword_init: true) unless defined?(Employee)

  let(:employees) do
    [
      Employee.new(annual_salary: 100_000, bonus: 5_000, department: 'Engineering', designation: 'Engineer', pay_band: 'C', active: true),
      Employee.new(annual_salary: 80_000, bonus: 2_000, department: 'Finance', designation: 'Analyst', pay_band: 'B', active: true)
    ]
  end

  it 'aggregates records and applies filters' do
    report = described_class.new(employees, batch_size: 1).generate(department: 'engineering')

    expect(report[:total_employees]).to eq(1)
    expect(report[:total_payroll]).to eq(105_000.0)
    expect(report[:by_department]['Engineering'][:count]).to eq(1)
  end
end
