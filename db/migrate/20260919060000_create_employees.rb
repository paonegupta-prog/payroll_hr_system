# frozen_string_literal: true

class CreateEmployees < ActiveRecord::Migration[7.1]
  def change
    create_table :employees do |t|
      t.string :name, null: false
      t.string :department, null: false
      t.string :designation, null: false
      t.decimal :annual_salary, precision: 12, scale: 2, null: false
      t.decimal :bonus, precision: 12, scale: 2, null: false, default: 0.0
      t.string :pay_band, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :employees, :department
    add_index :employees, :designation
    add_index :employees, :pay_band
    add_index :employees, :active
    add_index :employees, %i[department designation pay_band], name: 'index_employees_on_org_filters'
  end
end
