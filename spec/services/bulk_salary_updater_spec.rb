# frozen_string_literal: true

require_relative '../../app/services/bulk_salary_updater'

RSpec.describe BulkSalaryUpdater do
  let(:relation) { instance_double('EmployeeRelation') }

  before do
    stub_const('Employee', class_double('Employee', all: relation))
  end

  it 'updates a department with one bulk SQL operation' do
    allow(relation).to receive(:where).with(department: 'Engineering').and_return(relation)
    allow(relation).to receive(:klass).and_return(Employee)
    allow(Employee).to receive(:transaction).and_yield
    expect(relation).to receive(:update_all) do |attributes|
      expect(attributes[:annual_salary]).to be_a(Arel::Nodes::SqlLiteral)
      25
    end

    result = described_class.new(relation).increase_by_department(department: 'Engineering', percentage: 10)

    expect(result).to eq({ updated_count: 25, percentage: 10.0 })
  end

  it 'rejects missing departments and negative percentages' do
    updater = described_class.new(relation)

    expect { updater.increase_by_department(department: '', percentage: 10) }
      .to raise_error(ArgumentError, 'department is required')
    expect { updater.increase_by_department(department: 'Engineering', percentage: -1) }
      .to raise_error(ArgumentError, 'percentage must be non-negative')
  end
end
