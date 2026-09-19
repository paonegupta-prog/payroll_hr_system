# frozen_string_literal: true

require 'faker'

puts 'Seeding 10,000 employees...'

Faker::Config.random = Random.new(12_345)

DEPARTMENTS = ['Engineering', 'Finance', 'Human Resources', 'Sales', 'Product'].freeze
DESIGNATIONS = ['Junior', 'Mid-Level', 'Senior', 'Lead', 'Manager'].freeze

pay_band_for = lambda do |salary|
  case salary
  when 0...50_000 then 'A'
  when 50_000...90_000 then 'B'
  when 90_000...140_000 then 'C'
  else 'D'
  end
end

10_000.times.each_slice(1_000) do |slice|
  now = Time.current
  rows = slice.map do
    salary = rand(45_000..180_000)
    {
      name: Faker::Name.name,
      department: DEPARTMENTS.sample,
      designation: DESIGNATIONS.sample,
      annual_salary: salary,
      bonus: rand(0..15_000),
      pay_band: pay_band_for.call(salary),
      active: true,
      created_at: now,
      updated_at: now
    }
  end

  Employee.insert_all(rows)
end

puts 'Successfully seeded 10,000 records!'
