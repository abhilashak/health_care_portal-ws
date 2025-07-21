# frozen_string_literal: true

require_relative "application_model_test_case"

class HospitalTest < ApplicationModelTestCase
  def setup
    @valid_attributes = {
      name: "Test General Hospital",
      address: "456 Hospital Ave\nMedical City, ST 54321",
      phone: "+1-555-987-6543",
      email: "info@testgeneralhospital.com",
      registration_number: "HOSP123456",
      facility_type: "general",
      operating_hours: {
        "monday" => "24/7",
        "emergency" => "24/7",
        "outpatient" => "8:00-18:00"
      },
      status: "active",
      specialties: [ "Cardiology", "Neurology", "Emergency Medicine" ]
    }
  end

  # STI Tests
  test "should be a Hospital" do
    hospital = Hospital.new(@valid_attributes)
    assert_equal "Hospital", hospital.type
    assert hospital.is_a?(Hospital)
    assert hospital.is_a?(HealthcareFacility)
  end

  test "should be valid with valid attributes" do
    hospital = Hospital.new(@valid_attributes)
    assert hospital.valid?, "Hospital should be valid with valid attributes"
  end

  # Hospital-specific Validation Tests
  test "should validate facility_type inclusion for hospitals" do
    valid_types = %w[general childrens teaching research military specialty other]
    valid_types.each do |type|
      hospital = Hospital.new(@valid_attributes.merge(facility_type: type))
      assert hospital.valid?, "Hospital type #{type} should be valid"
    end

    hospital = Hospital.new(@valid_attributes.merge(facility_type: "invalid_hospital_type"))
    assert_not hospital.valid?
    assert_includes hospital.errors[:facility_type], "invalid_hospital_type is not a valid hospital type"
  end

  test "should validate specialties are from allowed list" do
    valid_specialties = [ "Cardiology", "Neurology", "Oncology" ]
    hospital = Hospital.new(@valid_attributes.merge(specialties: valid_specialties))
    assert hospital.valid?, "Hospital should be valid with valid specialties"

    invalid_specialties = [ "Cardiology", "Invalid Specialty" ]
    hospital = Hospital.new(@valid_attributes.merge(specialties: invalid_specialties))
    assert_not hospital.valid?
    assert_includes hospital.errors[:specialties], "contains invalid specialties: Invalid Specialty"
  end

  # Scope Tests
  test "by_hospital_type scope should filter by hospital type" do
    general_hospital = Hospital.create!(@valid_attributes.merge(facility_type: "general"))
    teaching_hospital = Hospital.create!(@valid_attributes.merge(
      name: "Teaching Hospital",
      phone: "+1-555-111-2222",
      email: "teaching@hospital.com",
      registration_number: "TEACH123",
      facility_type: "teaching"
    ))

    general_hospitals = Hospital.by_hospital_type("general")
    assert_includes general_hospitals, general_hospital
    assert_not_includes general_hospitals, teaching_hospital
  end

  test "with_emergency_services scope should return hospitals with emergency services" do
    emergency_hospital = Hospital.create!(@valid_attributes)
    regular_hospital = Hospital.create!(@valid_attributes.merge(
      name: "Regular Hospital",
      phone: "+1-555-111-2222",
      email: "regular@hospital.com",
      registration_number: "REG123",
      operating_hours: { "monday" => "9:00-17:00" }
    ))

    emergency_hospitals = Hospital.with_emergency_services
    assert_includes emergency_hospitals, emergency_hospital
    assert_not_includes emergency_hospitals, regular_hospital
  end

  # Class Method Tests
  test "hospital_types should return valid hospital types" do
    expected_types = %w[general childrens teaching research military specialty other]
    assert_equal expected_types, Hospital.hospital_types
  end

  test "available_specialties should return valid specialties" do
    specialties = Hospital.available_specialties
    assert_includes specialties, "Cardiology"
    assert_includes specialties, "Neurology"
    assert_includes specialties, "Emergency Medicine"
    assert specialties.is_a?(Array)
  end

  # Instance Method Tests
  test "emergency_services_available? should return true when emergency hours present" do
    hospital = Hospital.create!(@valid_attributes)
    assert hospital.emergency_services_available?
  end

  test "emergency_services_available? should return false when no emergency hours" do
    hospital = Hospital.create!(@valid_attributes.merge(
      operating_hours: { "monday" => "9:00-17:00" }
    ))
    assert_not hospital.emergency_services_available?
  end

  test "teaching_hospital? should return true for teaching hospitals" do
    hospital = Hospital.create!(@valid_attributes.merge(facility_type: "teaching"))
    assert hospital.teaching_hospital?
  end

  test "teaching_hospital? should return false for non-teaching hospitals" do
    hospital = Hospital.create!(@valid_attributes.merge(facility_type: "general"))
    assert_not hospital.teaching_hospital?
  end

  test "add_specialty should add valid specialty" do
    hospital = Hospital.create!(@valid_attributes.merge(specialties: [ "Cardiology" ]))
    hospital.add_specialty("Neurology")
    assert_includes hospital.specialties, "Neurology"
  end

  test "add_specialty should not add invalid specialty" do
    hospital = Hospital.create!(@valid_attributes.merge(specialties: [ "Cardiology" ]))
    original_specialties = hospital.specialties.dup
    hospital.add_specialty("Invalid Specialty")
    assert_equal original_specialties, hospital.specialties
  end

  test "add_specialty should not add duplicate specialty" do
    hospital = Hospital.create!(@valid_attributes.merge(specialties: [ "Cardiology" ]))
    hospital.add_specialty("Cardiology")
    assert_equal 1, hospital.specialties.count("Cardiology")
  end

  test "add_specialty should handle different cases" do
    hospital = Hospital.create!(@valid_attributes.merge(specialties: []))
    hospital.add_specialty("cardiology")
    assert_includes hospital.specialties, "Cardiology"
  end

  test "remove_specialty should remove existing specialty" do
    hospital = Hospital.create!(@valid_attributes.merge(specialties: [ "Cardiology", "Neurology" ]))
    hospital.remove_specialty("Cardiology")
    assert_not_includes hospital.specialties, "Cardiology"
    assert_includes hospital.specialties, "Neurology"
  end

  test "remove_specialty should handle case insensitive removal" do
    hospital = Hospital.create!(@valid_attributes.merge(specialties: [ "Cardiology" ]))
    hospital.remove_specialty("cardiology")
    assert_not_includes hospital.specialties, "Cardiology"
  end

  test "remove_specialty should handle non-existent specialty gracefully" do
    hospital = Hospital.create!(@valid_attributes.merge(specialties: [ "Cardiology" ]))
    original_specialties = hospital.specialties.dup
    hospital.remove_specialty("Non-existent")
    assert_equal original_specialties, hospital.specialties
  end

  # Inheritance Tests
  test "should inherit all HealthcareFacility validations" do
    hospital = Hospital.new(@valid_attributes.except(:name))
    assert_not hospital.valid?
    assert_includes hospital.errors[:name], "can't be blank"
  end

  test "should inherit all HealthcareFacility scopes" do
    hospital = Hospital.create!(@valid_attributes)
    assert_includes Hospital.active, hospital
    assert_includes Hospital.hospitals, hospital
    assert_not_includes Hospital.clinics, hospital
  end

  test "should inherit all HealthcareFacility instance methods" do
    hospital = Hospital.create!(@valid_attributes)
    assert hospital.respond_to?(:active?)
    assert hospital.respond_to?(:hospital?)
    assert hospital.respond_to?(:clinic?)
    assert hospital.respond_to?(:display_address)
    assert hospital.respond_to?(:primary_contact)
  end
end
