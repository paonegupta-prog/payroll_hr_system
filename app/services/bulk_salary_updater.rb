# frozen_string_literal: true

require_relative '../errors/payroll_errors'

class BulkSalaryUpdater
  DEFAULT_BATCH_SIZE = 1_000

  def initialize(scope = Employee.all, batch_size: DEFAULT_BATCH_SIZE)
    @scope = scope
    @batch_size = Integer(batch_size)
    raise Payroll::InvalidPayrollParameterError, 'batch size must be positive' unless @batch_size.positive?
  rescue TypeError, ArgumentError => error
    raise error if error.is_a?(Payroll::InvalidPayrollParameterError)

    raise Payroll::InvalidPayrollParameterError, 'batch size must be numeric'
  end

  def increase_by_department(department:, percentage:)
    validate_department!(department)
    percentage = validate_percentage!(percentage)
    relation = @scope.where(department: department)
    multiplier = 1 + (percentage / 100.0)

    updated_count = transaction do
      relation.update_all(annual_salary: Arel.sql("annual_salary * #{multiplier}"))
    end

    { updated_count: updated_count, percentage: percentage }
  end

  def enqueue_payroll_jobs(job_class: ProcessPayrollJob)
    raise Payroll::InvalidPayrollParameterError, 'job class is required' if job_class.nil?
    return 0 unless @scope.respond_to?(:find_in_batches)

    processed = 0
    @scope.find_in_batches(batch_size: @batch_size) do |batch|
      batch.each do |employee|
        job_class.perform_later(employee.id)
        processed += 1
      end
    end
    processed
  end

  private

  def transaction(&block)
    if @scope.respond_to?(:klass) && @scope.klass.respond_to?(:transaction)
      @scope.klass.transaction(&block)
    else
      yield
    end
  end

  def validate_department!(department)
    raise Payroll::InvalidPayrollParameterError, 'department is required' if department.to_s.strip.empty?
  end

  def validate_percentage!(percentage)
    raise Payroll::InvalidPayrollParameterError, 'percentage is required' if percentage.nil?

    value = Float(percentage)
    raise Payroll::InvalidPayrollParameterError, 'percentage must be non-negative' if value.negative?

    value
  rescue TypeError, ArgumentError => error
    raise error if error.is_a?(Payroll::InvalidPayrollParameterError)

    raise Payroll::InvalidPayrollParameterError, 'percentage must be numeric'
  end
end
