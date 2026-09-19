# Payroll HR System

A Ruby/Rails payroll and HR domain prototype designed around test-driven development, small service objects, and batch-safe processing for datasets of 10,000+ employees.

## Features

- Salary, net-pay, tax, and bonus-tier calculations
- Progressive tax deduction rules
- Payroll reports filterable by department, designation, and pay band
- Batch-oriented aggregation for large employee datasets
- Transactional bulk salary updates without N+1 record updates
- Explicit domain errors for invalid or missing payroll inputs
- RSpec tests and RuboCop verification

## Architecture

### Domain services instead of heavy Active Record models

Core payroll rules live in plain old Ruby objects under `app/services/`:

- `SalaryCalculator` calculates monthly base pay, net pay, and bonus tiers.
- `TaxDeductionService` owns progressive tax brackets and tax validation.
- `PayrollReportGenerator` produces filtered payroll summaries and grouped totals.
- `BulkSalaryUpdater` handles reliable department-wide salary changes and optional job enqueueing.

Active Record models should remain responsible for persistence concerns, associations, scopes, and simple validations. Keeping payroll math in POROs makes the rules easier to unit test, reuse outside controllers, and change without coupling business behavior to database callbacks or Rails request lifecycle code. It also follows single-responsibility and dependency-inversion principles: services receive data or relations rather than knowing about presentation concerns.

### Batch processing and background jobs

`PayrollReportGenerator` supports Active Record relations through `find_in_batches(batch_size: 1_000)`. Only one batch is materialized at a time, which bounds Ruby memory usage while still allowing the service to process large datasets. For ordinary arrays, it falls back to `each_slice`.

For work that must happen for each employee, `BulkSalaryUpdater#enqueue_payroll_jobs` uses the same batch boundary and schedules a job with the employee ID rather than passing a large object through the queue:

```ruby
Employee.find_in_batches(batch_size: 1_000) do |batch|
  batch.each do |employee|
    ProcessPayrollJob.perform_later(employee.id)
  end
end
```

For dashboard-only summaries, database-level aggregation is preferable because the database can calculate results without instantiating every row:

```ruby
Employee.group(:department).average(:annual_salary)
```

### Bulk salary updates

`BulkSalaryUpdater` scopes employees by department and performs one `update_all` inside a transaction. This avoids an N+1 loop and reduces memory usage:

```ruby
Employee.where(department: department)
        .update_all('annual_salary = annual_salary * 1.10')
```

This deliberately bypasses model callbacks and validations. When callbacks, audit events, or per-employee side effects are required, use the batch/job path instead. The service validates parameters before constructing the SQL expression and returns the affected-row count.

### Error handling

Domain-specific errors make failures explicit at service boundaries:

- `Payroll::InvalidSalaryError`
- `Payroll::InvalidIncomeError`
- `Payroll::InvalidPayrollParameterError`

Zero is valid for mathematical calculations such as base salary and tax. Missing, non-numeric, and negative values are rejected where they would represent invalid payroll data.

## AI Collaboration Workflow

AI was used as a development assistant, not as an unchecked source of production code. The workflow followed Red-Green-Refactor cycles:

1. **Red:** ask for a focused RSpec example for one rule or edge case.
2. **Green:** implement the smallest service method that satisfies the example.
3. **Refactor:** extract tax rules, validation, batching, and reporting responsibilities while rerunning the suite.
4. **Review:** inspect generated code for Rails conventions, SQL safety, memory behavior, and domain correctness before accepting it.

Representative prompts included:

- “Write an RSpec example for annual salary divided by twelve, including zero and negative salary cases.”
- “Implement the minimum `SalaryCalculator` PORO needed to pass this spec.”
- “Extract progressive tax brackets into `TaxDeductionService` and preserve the existing behavior.”
- “Design a payroll report service that supports `find_in_batches` without loading 10,000 employees at once.”
- “Implement a transactional bulk salary update without an N+1 loop and add tests for invalid parameters.”
- “Review this service for RuboCop issues, callback behavior, SQL safety, and scaling trade-offs.”

### AI output that was corrected or rejected

Several tempting patterns were intentionally not accepted without review:

- Putting tax formulas and report aggregation directly in an Active Record model was rejected because it would create a large, multi-responsibility model.
- Loading `Employee.all` and calling `sum`, `group_by`, or `map` in Ruby was rejected for large reports because it materializes the full dataset.
- Calling `employee.update!` inside a loop was rejected for bulk salary changes because it creates N database writes and may trigger expensive callbacks.
- Using generic `ArgumentError` everywhere was replaced with domain-specific errors so callers can distinguish invalid salary, income, and bulk-operation parameters.
- Passing complete employee objects to background jobs was rejected; jobs receive stable IDs and reload current data when they execute.
- Any generated SQL interpolation was reviewed carefully. Dynamic values are validated and the update expression is limited to a numeric multiplier; production implementations should prefer adapter-specific arithmetic/Arel or a tested query object.

AI suggestions were therefore treated as proposals. Human review determined the domain boundaries, zero/negative-value policy, batch size, callback trade-off, and which behavior required tests.

## Trade-offs and Scale Considerations

### Around 10,000 employees

For 10,000 records, `find_in_batches(batch_size: 1_000)` offers a practical balance between query overhead and memory consumption. A smaller batch reduces memory but increases round trips; a larger batch reduces round trips but increases object allocation and garbage-collection pressure.

Use database aggregation for simple totals and averages. Use Ruby services only when the calculation is difficult to express in SQL, requires domain objects, or needs per-employee behavior.

### Beyond 10,000 records

As the dataset grows, synchronous report generation can increase request latency and database load. The next scaling step is to:

- enqueue report generation in Sidekiq or another worker pool;
- persist report status and results so the UI can poll or receive a notification;
- partition work by department, pay period, or employee ID range;
- use read replicas for reporting where consistency requirements allow it;
- add indexes for filter columns such as `department`, `designation`, `pay_band`, and `active`;
- use database aggregates for dashboards and precomputed summaries for frequently requested reports;
- make jobs idempotent and retry-safe;
- instrument batch duration, rows processed, failures, and database time.

The trade-off is operational complexity: asynchronous workers improve throughput and request responsiveness, but require job monitoring, retries, locking/idempotency design, and result lifecycle management.

Bulk SQL updates are fast and memory-efficient but bypass callbacks, validations, and audit hooks. Batch jobs are slower and more operationally complex, but are the correct choice when each employee update must emit events or perform additional domain work.

## Setup

### Prerequisites

- Ruby compatible with the project’s `.ruby-version`
- Bundler
- PostgreSQL
- Rails (for the full Rails application workflow)

### Install and initialize

```bash
git clone https://github.com/paonegupta-prog/payroll_hr_system.git
cd payroll_hr_system
bundle install
rails db:setup
```

If the application has not yet generated the RSpec files in a fresh checkout, run:

```bash
rails generate rspec:install
```

Configure local PostgreSQL credentials through `config/database.yml` or environment variables. Do not commit credentials, `.env` files, `config/master.key`, or other secrets.

## Test and verification commands

Run the complete test suite:

```bash
bundle exec rspec
```

Run the style checks:

```bash
bundle exec rubocop
```

Run one focused service spec during TDD:

```bash
bundle exec rspec spec/services/salary_calculator_spec.rb
```

The expected commit sequence follows the workflow:

```bash
git commit -m "test: add test for tax bracket calculation"
git commit -m "feat: implement base salary calculation logic"
git commit -m "refactor: extract tax rules into service object"
```

## Project layout

```text
app/
  errors/payroll_errors.rb
  services/
    bulk_salary_updater.rb
    payroll_report_generator.rb
    salary_calculator.rb
    tax_deduction_service.rb
spec/
  services/
    bulk_salary_updater_spec.rb
    payroll_report_generator_spec.rb
    salary_calculator_spec.rb
    tax_deduction_service_spec.rb
.rubocop.yml
Gemfile
README.md
```

## License

This project is provided as an evaluation and learning example.
