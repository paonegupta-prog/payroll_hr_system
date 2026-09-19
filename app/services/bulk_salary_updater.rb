# frozen_string_literal: true

class BulkSalaryUpdater
  DEFAULT_BATCH_SIZE = 1_000

  def initialize(scope = Employee.all, batch_size: DEFAULT_BATCH_SIZE)
    @scope = scope
    @batch_size = batch_size
    raise ArgumentError, 'batch size must be positive' unless batch_size.to_i.positive?
  end

  # Performs one database UPDATE for an ActiveRecord relation. This avoids
  # instantiating every employee and avoids an N+1 callback/update loop.
  def increase_by_department(department:, percentage:)
    validate_department!(department)
    percentage = validate_percentage!(percentage)
    relation = filtered_scope(department)
    multiplier = 1 + (percentage / 100.0)

    updated_count = transaction do
      relation.update_all(annual_salary: Arel.sql("annual_salary * #{multiplier}"))
    end

    { updated_count: updated_count, percentage: percentage }
  end

  # Use this variant when each employee must be processed by an application
  # service or background job. It keeps memory bounded and preserves ordering.
  def enqueue_payroll_jobs(job_class: ProcessPayrollJob)
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

  def filtered_scope(department)
    @scope.where(department: department)
  end

  def transaction(&block)
    if @scope.respond_to?(:klass) && @scope.klass.respond_to?(:transaction)
      @scope.klass.transaction(&block)
    else
      yield
    end
  end

  def validate_department!(department)
    raise ArgumentError, 'department is required' if department.to_s.strip.empty?
  end

  def validate_percentage!(percentage)
    value = Float(percentage)
    raise ArgumentError, 'percentage must be non-negative' if value.negative?

    value
  rescue TypeError, ArgumentError => error
    raise error if error.message == 'percentage must be non-negative'

    raise ArgumentError, 'percentage must be numeric'
  end
end
