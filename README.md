# Payroll HR System

A Ruby/Rails payroll and HR domain prototype designed around test-driven development, small service objects, and batch-safe processing for datasets of 10,000+ employees.

## Architecture

Core payroll rules live in plain old Ruby objects under `app/services/`:

- `SalaryCalculator` calculates monthly base pay, net pay, and bonus tiers.
- `TaxDeductionService` owns progressive tax brackets and tax validation.
- `PayrollReportGenerator` supports filtered reporting and bounded-memory batch aggregation.
- `BulkSalaryUpdater` performs transactional department-wide changes without an N+1 update loop.

Active Record is responsible for persistence, associations, scopes, indexes, and simple input validations. Keeping payroll math in POROs makes business rules independently testable and prevents a large, multi-responsibility model. `find_in_batches(batch_size: 1_000)` keeps only one batch in memory; database-level aggregates such as `Employee.group(:department).average(:annual_salary)` are preferred for simple dashboard statistics.

Bulk SQL updates are efficient but bypass callbacks and validations. When audit events or per-employee side effects are required, use the batch/job path instead. Beyond 10,000 records, move long-running reports and per-employee payroll work to Sidekiq or another worker pool, partition work, make jobs idempotent, and persist report status/results.

## AI collaboration workflow

AI was used to suggest PORO boundaries, RSpec examples, progressive-tax calculations, batch-processing patterns, and RuboCop cleanup. Development followed Red-Green-Refactor: write a focused failing spec, implement the smallest passing behavior, then refactor and verify.

Human review corrected or rejected suggestions that placed tax/report logic in Active Record models, loaded `Employee.all` into memory, called `update!` once per employee, used generic errors for domain failures, or passed complete employee objects to jobs. The accepted design uses domain-specific errors, bounded batches, employee IDs in jobs, and explicit review of SQL/callback trade-offs.

## Setup

Prerequisites: Ruby, Bundler, Rails, and PostgreSQL.

```bash
git clone https://github.com/paonegupta-prog/payroll_hr_system.git
cd payroll_hr_system
bundle install
rails db:create db:migrate
rails db:seed
```

The seed task creates 10,000 deterministic sample employees using `insert_all` in batches of 1,000. To reset the local database and reseed it, run `rails db:reset` followed by `rails db:seed`.

## Verification

```bash
bundle exec rspec
bundle exec rubocop
```

Focused TDD verification:

```bash
bundle exec rspec spec/services/salary_calculator_spec.rb
```

Before submission, confirm `app/`, `spec/`, `db/migrate/`, `db/seeds.rb`, `Gemfile`, and `README.md` are committed and pushed to `main`.

## Project layout

```text
app/
  models/employee.rb
  errors/payroll_errors.rb
  services/
    bulk_salary_updater.rb
    payroll_report_generator.rb
    salary_calculator.rb
    tax_deduction_service.rb
db/
  migrate/*_create_employees.rb
  seeds.rb
spec/services/
.rubocop.yml
Gemfile
README.md
```
