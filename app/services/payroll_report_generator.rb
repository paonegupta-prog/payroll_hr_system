# frozen_string_literal: true

class PayrollReportGenerator
  DEFAULT_BATCH_SIZE = 1_000

  def initialize(employees, batch_size: DEFAULT_BATCH_SIZE)
    @employees = employees
    @batch_size = batch_size
    raise ArgumentError, 'batch size must be positive' unless batch_size.to_i.positive?
  end

  def generate(filters = {})
    report = empty_report
    each_batch do |batch|
      batch.each do |employee|
        next unless eligible?(employee, filters)

        add_employee(report, employee)
      end
    end
    finalize(report)
  end

  private

  def each_batch(&block)
    if @employees.respond_to?(:find_in_batches)
      @employees.find_in_batches(batch_size: @batch_size, &block)
    else
      @employees.each_slice(@batch_size, &block)
    end
  end

  def eligible?(employee, filters)
    employee.active != false &&
      matches?(employee, :department, filters[:department]) &&
      matches?(employee, :designation, filters[:designation]) &&
      matches?(employee, :pay_band, filters[:pay_band])
  end

  def matches?(employee, attribute, expected)
    expected.nil? || employee.public_send(attribute).to_s.casecmp?(expected.to_s)
  end

  def empty_report
    { total_employees: 0, total_payroll: 0.0, total_salary: 0.0, total_bonus: 0.0,
      total_tax: 0.0, by_department: {}, by_pay_band: {} }
  end

  def add_employee(report, employee)
    salary = employee.annual_salary.to_f
    bonus = employee.respond_to?(:bonus) ? employee.bonus.to_f : 0.0
    report[:total_employees] += 1
    report[:total_salary] += salary
    report[:total_bonus] += bonus
    report[:total_payroll] += salary + bonus
    report[:total_tax] += TaxDeductionService.calculate_for(salary + bonus)[:total_tax]
    add_group(report[:by_department], employee.department, salary)
    add_group(report[:by_pay_band], employee.pay_band, salary)
  end

  def add_group(groups, key, salary)
    group = (groups[key] ||= { count: 0, total_salary: 0.0 })
    group[:count] += 1
    group[:total_salary] += salary
  end

  def finalize(report)
    report[:average_salary] = report[:total_employees].zero? ? 0.0 : report[:total_salary] / report[:total_employees]
    report[:by_department].each_value { |group| add_average(group) }
    report[:by_pay_band].each_value { |group| add_average(group) }
    report
  end

  def add_average(group)
    group[:average_salary] = group[:total_salary] / group[:count]
  end
end
