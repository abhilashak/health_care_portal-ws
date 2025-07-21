# frozen_string_literal: true

class HealthcareFacility < ApplicationRecord
  # Constants
  STATUSES = %w[active inactive suspended].freeze
  FACILITY_TYPES = %w[primary_care specialty urgent_care dental vision other].freeze

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :address, presence: true
  validates :phone, presence: true, uniqueness: true,
                    format: { with: /\A\+?[\d\s\-()]{10,}\z/, message: "must be a valid phone number" }
  validates :email, presence: true, uniqueness: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a valid email address" }
  validates :registration_number, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES, message: "%{value} is not a valid status" }
  validates :facility_type, inclusion: { in: FACILITY_TYPES, message: "%{value} is not a valid facility type" }, allow_nil: true

  # Scopes
  scope :active, -> { where(active: true) }
  scope :hospitals, -> { where(type: "Hospital") }
  scope :clinics, -> { where(type: "Clinic") }
  scope :accepting_new_patients, -> { where(accepts_new_patients: true) }
  scope :accepting_insurance, -> { where(accepts_insurance: true) }
  scope :search_by_name, ->(query) { where("name ILIKE ?", "%#{query}%") }
  scope :by_specialty, ->(specialty) { where("? = ANY(specialties)", specialty) }
  scope :by_service, ->(service) { where("? = ANY(services)", service) }

  # Callbacks
  before_validation :normalize_phone_number
  before_save :normalize_email

  # Instance Methods
  def active?
    active && status == "active"
  end

  def hospital?
    type == "Hospital"
  end

  def clinic?
    type == "Clinic"
  end

  def display_address
    address.gsub("\n", ", ")
  end

  def primary_contact
    contact_person.present? ? "#{contact_person} (#{contact_person_phone})" : phone
  end

  def emergency_contact_info
    emergency_contact.present? ? "#{emergency_contact} (#{emergency_phone})" : "Not specified"
  end

  private

  def normalize_phone_number
    return if phone.blank?
    self.phone = phone.gsub(/[^0-9+]/, "")
  end

  def normalize_email
    self.email = email.to_s.downcase.strip if email.present?
  end
end
