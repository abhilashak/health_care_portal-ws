# frozen_string_literal: true

class Clinic < HealthcareFacility
  # Associations
  has_many :doctors, foreign_key: "clinic_id", dependent: :nullify

  # Constants
  CLINIC_TYPES = %w[primary_care specialty urgent_care dental vision other].freeze
  CLINIC_SERVICES = [
    "General Checkup", "Vaccinations", "Lab Testing", "X-ray", "Ultrasound",
    "Physical Therapy", "Dental Cleaning", "Eye Exam", "Vaccinations", "Minor Surgery",
    "Chronic Disease Management", "Women's Health", "Pediatric Care", "Mental Health",
    "Nutrition Counseling", "Travel Medicine", "Allergy Testing", "Vaccinations",
    "Occupational Health", "Sports Physicals"
  ].freeze

  # Validations
  validates :facility_type, inclusion: { in: CLINIC_TYPES, message: "%{value} is not a valid clinic type" }, allow_nil: true
  validates :number_of_doctors, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validate :validate_services

  # Scopes
  scope :by_clinic_type, ->(type) { where(facility_type: type) }
  scope :accepting_insurance, -> { where(accepts_insurance: true) }
  scope :accepting_new_patients, -> { where(accepts_new_patients: true) }

  # Class Methods
  def self.clinic_types
    CLINIC_TYPES
  end

  def self.available_services
    CLINIC_SERVICES
  end

  # Instance Methods
  def add_service(service)
    return if service.blank?
    service = service.to_s.strip.titleize
    self.services = (services + [ service ]).uniq if CLINIC_SERVICES.include?(service)
  end

  def remove_service(service)
    return if service.blank?
    self.services = services.reject { |s| s.casecmp?(service.to_s.strip) }
  end

  def add_language(language)
    return if language.blank?
    language = language.to_s.strip.capitalize
    self.languages_spoken = (languages_spoken + [ language ]).uniq
  end

  def remove_language(language)
    return if language.blank?
    self.languages_spoken = languages_spoken.reject { |l| l.casecmp?(language.to_s.strip) }
  end

  def walk_in_hours
    operating_hours["walk_in"]
  end

  def appointment_hours
    operating_hours["appointment"]
  end

  private

  def validate_services
    return if services.blank?

    invalid_services = services.reject { |s| CLINIC_SERVICES.include?(s) }
    return if invalid_services.empty?

    errors.add(:services, "contains invalid services: #{invalid_services.join(', ')}")
  end
end
