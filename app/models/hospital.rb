# frozen_string_literal: true

class Hospital < HealthcareFacility
  # Associations
  has_many :doctors, foreign_key: "hospital_id", dependent: :nullify

  # Constants
  HOSPITAL_TYPES = %w[general childrens teaching research military specialty other].freeze
  HOSPITAL_SPECIALTIES = [
    "Cardiology", "Neurology", "Oncology", "Pediatrics", "Orthopedics", "Gynecology",
    "Dermatology", "Ophthalmology", "Psychiatry", "Radiology", "Surgery", "Urology",
    "Emergency Medicine", "Intensive Care", "Neonatology", "Pathology", "Physical Therapy"
  ].freeze

  # Validations
  validates :facility_type, inclusion: { in: HOSPITAL_TYPES, message: "%{value} is not a valid hospital type" }, allow_nil: true
  validate :validate_specialties

  # Scopes
  scope :by_hospital_type, ->(type) { where(facility_type: type) }
  scope :with_emergency_services, -> { where("operating_hours->>'emergency' IS NOT NULL") }

  # Class Methods
  def self.hospital_types
    HOSPITAL_TYPES
  end

  def self.available_specialties
    HOSPITAL_SPECIALTIES
  end

  # Instance Methods
  def emergency_services_available?
    operating_hours["emergency"].present?
  end

  def teaching_hospital?
    facility_type == "teaching"
  end

  def add_specialty(specialty)
    return if specialty.blank?
    specialty = specialty.to_s.strip.titleize
    self.specialties = (specialties + [ specialty ]).uniq if HOSPITAL_SPECIALTIES.include?(specialty)
  end

  def remove_specialty(specialty)
    return if specialty.blank?
    self.specialties = specialties.reject { |s| s.casecmp?(specialty.to_s.strip) }
  end

  private

  def validate_specialties
    return if specialties.blank?

    invalid_specialties = specialties.reject { |s| HOSPITAL_SPECIALTIES.include?(s) }
    return if invalid_specialties.empty?

    errors.add(:specialties, "contains invalid specialties: #{invalid_specialties.join(', ')}")
  end
end
