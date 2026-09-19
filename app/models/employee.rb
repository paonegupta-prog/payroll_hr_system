# frozen_string_literal: true

class Employee < ActiveRecord::Base
  validates :name, :department, :designation, :pay_band, presence: true
  validates :annual_salary, numericality: { greater_than: 0 }
  validates :bonus, numericality: { greater_than_or_equal_to: 0 }

  scope :active, -> { where(active: true) }
  scope :in_department, ->(department) { where(department: department) }
  scope :in_designation, ->(designation) { where(designation: designation) }
  scope :in_pay_band, ->(pay_band) { where(pay_band: pay_band) }
end
