# frozen_string_literal: true

class Doctor < ApplicationRecord
  # Validations
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :specialization, presence: true

  # Associations
  belongs_to :hospital, class_name: "HealthcareFacility", foreign_key: "hospital_id", optional: true
  belongs_to :clinic, class_name: "HealthcareFacility", foreign_key: "clinic_id", optional: true
  has_many :appointments, dependent: :destroy

  # Scopes
  scope :by_specialization, ->(specialization) { where(specialization: specialization) }
  scope :at_hospital, ->(hospital_id) { where(hospital_id: hospital_id) }
  scope :at_clinic, ->(clinic_id) { where(clinic_id: clinic_id) }
  scope :search_by_name, ->(query) { where("first_name ILIKE ? OR last_name ILIKE ?", "%#{query}%", "%#{query}%") }

  # Callbacks
  before_validation :normalize_names

  # Instance Methods
  def full_name
    "#{first_name} #{last_name}".strip
  end

  def display_name
    "Dr. #{full_name}"
  end

  def facilities
    [ hospital, clinic ].compact
  end

  def primary_facility
    hospital || clinic
  end

  def works_at_hospital?
    hospital_id.present?
  end

  def works_at_clinic?
    clinic_id.present?
  end

  def works_at_both?
    hospital_id.present? && clinic_id.present?
  end

  private

  def normalize_names
    self.first_name = first_name.to_s.strip.titleize if first_name.present?
    self.last_name = last_name.to_s.strip.titleize if last_name.present?
    self.specialization = specialization.to_s.strip.titleize if specialization.present?
  end
end
