# Payroll HR System

A Ruby/Rails payroll domain organized around small PORO service objects. Payroll calculations remain independent from persistence, while batch-oriented services provide a path to processing 10,000+ employees without loading the entire relation into memory.

## Architecture

- `SalaryCalculator` calculates monthly base pay, net pay, and bonus tiers.
- `TaxDeductionService` owns progressive tax brackets and tax validation.
- `PayrollReportGenerator` consumes arrays or Active Record relations in batches and aggregates payroll by department and pay band.
- `BulkSalaryUpdater` uses a transaction and one SQL `UPDATE` for department-wide changes, avoiding N+1 updates. Its job-enqueueing path uses `find_in_batches`.
- `Payroll::InvalidSalaryError`, `Payroll::InvalidIncomeError`, and `Payroll::InvalidPayrollParameterError` make invalid domain input explicit.

Zero is a valid numeric input for calculations such as base salary and tax; negative and missing values are rejected. This preserves meaningful zero-value reports while preventing invalid payroll records.

## Verification

Install dependencies and run the checks before committing:

```bash
bundle install
bundle exec rubocop
bundle exec rspec
```

Use focused checks during TDD:

```bash
bundle exec rspec spec/services/salary_calculator_spec.rb
```

## Scaling notes

`PayrollReportGenerator` uses `find_in_batches(batch_size: 1_000)` for Active Record relations and `each_slice` for in-memory collections. For dashboard-only statistics, prefer database-level operations such as `Employee.group(:department).average(:annual_salary)`. Bulk salary changes use `update_all` inside a transaction, trading model callbacks for predictable performance; callback-dependent workflows should use the batch/job path instead.

## AI collaboration log

AI was used to propose PORO boundaries, progressive-tax examples, batch-processing patterns, and edge-case specs. The implementation was guided and reviewed manually: zero remains valid for mathematical calculations, domain-specific errors replace generic `ArgumentError` at service boundaries, and bulk updates are isolated from callback-sensitive job processing. AI suggestions that mixed persistence and calculation responsibilities were rejected in favor of thin Active Record models.
