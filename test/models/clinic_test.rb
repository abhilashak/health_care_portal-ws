# frozen_string_literal: true

require_relative "application_model_test_case"

class ClinicTest < ApplicationModelTestCase
  def setup
    @valid_attributes = {
      name: "Test Family Clinic",
      address: "789 Clinic Blvd\nHealthcare District, ST 98765",
      phone: "+1-555-456-7890",
      email: "info@testfamilyclinic.com",
      registration_number: "CLINIC123456",
      facility_type: "primary_care",
      operating_hours: {
        "monday" => "8:00-17:00",
        "walk_in" => "8:00-12:00",
        "appointment" => "13:00-17:00"
      },
      status: "active",
      services: [ "General Checkup", "Vaccinations", "Lab Testing" ],
      number_of_doctors: 3,
      accepts_insurance: true,
      accepts_new_patients: true,
      languages_spoken: [ "English", "Spanish" ]
    }
  end

  # STI Tests
  test "should be a Clinic" do
    clinic = Clinic.new(@valid_attributes)
    assert_equal "Clinic", clinic.type
    assert clinic.is_a?(Clinic)
    assert clinic.is_a?(HealthcareFacility)
  end

  test "should be valid with valid attributes" do
    clinic = Clinic.new(@valid_attributes)
    assert clinic.valid?, "Clinic should be valid with valid attributes"
  end

  # Clinic-specific Validation Tests
  test "should validate facility_type inclusion for clinics" do
    valid_types = %w[primary_care specialty urgent_care dental vision other]
    valid_types.each do |type|
      clinic = Clinic.new(@valid_attributes.merge(facility_type: type))
      assert clinic.valid?, "Clinic type #{type} should be valid"
    end

    clinic = Clinic.new(@valid_attributes.merge(facility_type: "invalid_clinic_type"))
    assert_not clinic.valid?
    assert_includes clinic.errors[:facility_type], "invalid_clinic_type is not a valid clinic type"
  end

  test "should validate number_of_doctors is non-negative" do
    clinic = Clinic.new(@valid_attributes.merge(number_of_doctors: 5))
    assert clinic.valid?, "Clinic should be valid with positive number of doctors"

    clinic = Clinic.new(@valid_attributes.merge(number_of_doctors: 0))
    assert clinic.valid?, "Clinic should be valid with zero doctors"

    clinic = Clinic.new(@valid_attributes.merge(number_of_doctors: -1))
    assert_not clinic.valid?
    assert_includes clinic.errors[:number_of_doctors], "must be greater than or equal to 0"
  end

  test "should validate services are from allowed list" do
    valid_services = [ "General Checkup", "Vaccinations", "Lab Testing" ]
    clinic = Clinic.new(@valid_attributes.merge(services: valid_services))
    assert clinic.valid?, "Clinic should be valid with valid services"

    invalid_services = [ "General Checkup", "Invalid Service" ]
    clinic = Clinic.new(@valid_attributes.merge(services: invalid_services))
    assert_not clinic.valid?
    assert_includes clinic.errors[:services], "contains invalid services: Invalid Service"
  end

  # Scope Tests
  test "by_clinic_type scope should filter by clinic type" do
    primary_clinic = Clinic.create!(@valid_attributes.merge(facility_type: "primary_care"))
    urgent_clinic = Clinic.create!(@valid_attributes.merge(
      name: "Urgent Care Clinic",
      phone: "+1-555-111-2222",
      email: "urgent@clinic.com",
      registration_number: "URGENT123",
      facility_type: "urgent_care"
    ))

    primary_clinics = Clinic.by_clinic_type("primary_care")
    assert_includes primary_clinics, primary_clinic
    assert_not_includes primary_clinics, urgent_clinic
  end

  test "accepting_insurance scope should return clinics that accept insurance" do
    insurance_clinic = Clinic.create!(@valid_attributes.merge(accepts_insurance: true))
    no_insurance_clinic = Clinic.create!(@valid_attributes.merge(
      name: "No Insurance Clinic",
      phone: "+1-555-111-2222",
      email: "noinsurance@clinic.com",
      registration_number: "NOINS123",
      accepts_insurance: false
    ))

    insurance_clinics = Clinic.accepting_insurance
    assert_includes insurance_clinics, insurance_clinic
    assert_not_includes insurance_clinics, no_insurance_clinic
  end

  test "accepting_new_patients scope should return clinics accepting new patients" do
    accepting_clinic = Clinic.create!(@valid_attributes.merge(accepts_new_patients: true))
    not_accepting_clinic = Clinic.create!(@valid_attributes.merge(
      name: "Full Clinic",
      phone: "+1-555-111-2222",
      email: "full@clinic.com",
      registration_number: "FULL123",
      accepts_new_patients: false
    ))

    accepting_clinics = Clinic.accepting_new_patients
    assert_includes accepting_clinics, accepting_clinic
    assert_not_includes accepting_clinics, not_accepting_clinic
  end

  # Class Method Tests
  test "clinic_types should return valid clinic types" do
    expected_types = %w[primary_care specialty urgent_care dental vision other]
    assert_equal expected_types, Clinic.clinic_types
  end

  test "available_services should return valid services" do
    services = Clinic.available_services
    assert_includes services, "General Checkup"
    assert_includes services, "Vaccinations"
    assert_includes services, "Lab Testing"
    assert services.is_a?(Array)
  end

  # Instance Method Tests
  test "add_service should add valid service" do
    clinic = Clinic.create!(@valid_attributes.merge(services: [ "General Checkup" ]))
    clinic.add_service("Vaccinations")
    assert_includes clinic.services, "Vaccinations"
  end

  test "add_service should not add invalid service" do
    clinic = Clinic.create!(@valid_attributes.merge(services: [ "General Checkup" ]))
    original_services = clinic.services.dup
    clinic.add_service("Invalid Service")
    assert_equal original_services, clinic.services
  end

  test "add_service should not add duplicate service" do
    clinic = Clinic.create!(@valid_attributes.merge(services: [ "General Checkup" ]))
    clinic.add_service("General Checkup")
    assert_equal 1, clinic.services.count("General Checkup")
  end

  test "add_service should handle different cases" do
    clinic = Clinic.create!(@valid_attributes.merge(services: []))
    clinic.add_service("general checkup")
    assert_includes clinic.services, "General Checkup"
  end

  test "remove_service should remove existing service" do
    clinic = Clinic.create!(@valid_attributes.merge(services: [ "General Checkup", "Vaccinations" ]))
    clinic.remove_service("General Checkup")
    assert_not_includes clinic.services, "General Checkup"
    assert_includes clinic.services, "Vaccinations"
  end

  test "remove_service should handle case insensitive removal" do
    clinic = Clinic.create!(@valid_attributes.merge(services: [ "General Checkup" ]))
    clinic.remove_service("general checkup")
    assert_not_includes clinic.services, "General Checkup"
  end

  test "add_language should add language to languages_spoken" do
    clinic = Clinic.create!(@valid_attributes.merge(languages_spoken: [ "English" ]))
    clinic.add_language("French")
    assert_includes clinic.languages_spoken, "French"
  end

  test "add_language should not add duplicate language" do
    clinic = Clinic.create!(@valid_attributes.merge(languages_spoken: [ "English" ]))
    clinic.add_language("English")
    assert_equal 1, clinic.languages_spoken.count("English")
  end

  test "add_language should capitalize language" do
    clinic = Clinic.create!(@valid_attributes.merge(languages_spoken: []))
    clinic.add_language("spanish")
    assert_includes clinic.languages_spoken, "Spanish"
  end

  test "remove_language should remove existing language" do
    clinic = Clinic.create!(@valid_attributes.merge(languages_spoken: [ "English", "Spanish" ]))
    clinic.remove_language("English")
    assert_not_includes clinic.languages_spoken, "English"
    assert_includes clinic.languages_spoken, "Spanish"
  end

  test "remove_language should handle case insensitive removal" do
    clinic = Clinic.create!(@valid_attributes.merge(languages_spoken: [ "English" ]))
    clinic.remove_language("english")
    assert_not_includes clinic.languages_spoken, "English"
  end

  test "walk_in_hours should return walk-in operating hours" do
    clinic = Clinic.create!(@valid_attributes)
    assert_equal "8:00-12:00", clinic.walk_in_hours
  end

  test "appointment_hours should return appointment operating hours" do
    clinic = Clinic.create!(@valid_attributes)
    assert_equal "13:00-17:00", clinic.appointment_hours
  end

  test "walk_in_hours should return nil when not set" do
    clinic = Clinic.create!(@valid_attributes.merge(
      operating_hours: { "monday" => "8:00-17:00" }
    ))
    assert_nil clinic.walk_in_hours
  end

  test "appointment_hours should return nil when not set" do
    clinic = Clinic.create!(@valid_attributes.merge(
      operating_hours: { "monday" => "8:00-17:00" }
    ))
    assert_nil clinic.appointment_hours
  end

  # Inheritance Tests
  test "should inherit all HealthcareFacility validations" do
    clinic = Clinic.new(@valid_attributes.except(:name))
    assert_not clinic.valid?
    assert_includes clinic.errors[:name], "can't be blank"
  end

  test "should inherit all HealthcareFacility scopes" do
    clinic = Clinic.create!(@valid_attributes)
    assert_includes Clinic.active, clinic
    assert_includes Clinic.clinics, clinic
    assert_not_includes Clinic.hospitals, clinic
  end

  test "should inherit all HealthcareFacility instance methods" do
    clinic = Clinic.create!(@valid_attributes)
    assert clinic.respond_to?(:active?)
    assert clinic.respond_to?(:hospital?)
    assert clinic.respond_to?(:clinic?)
    assert clinic.respond_to?(:display_address)
    assert clinic.respond_to?(:primary_contact)
  end

  # Edge Cases
  test "should handle empty services array" do
    clinic = Clinic.create!(@valid_attributes.merge(services: []))
    assert clinic.valid?
    assert_equal [], clinic.services
  end

  test "should handle empty languages_spoken array" do
    clinic = Clinic.create!(@valid_attributes.merge(languages_spoken: []))
    assert clinic.valid?
    assert_equal [], clinic.languages_spoken
  end

  test "should handle nil number_of_doctors" do
    clinic = Clinic.create!(@valid_attributes.merge(number_of_doctors: nil))
    assert clinic.valid?
    assert_nil clinic.number_of_doctors
  end
end
