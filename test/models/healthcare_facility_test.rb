# frozen_string_literal: true

require_relative "application_model_test_case"

class HealthcareFacilityTest < ApplicationModelTestCase
  def setup
    @valid_attributes = {
      name: "Test Healthcare Facility",
      address: "123 Main St\nAnytown, ST 12345",
      phone: "+1-555-123-4567",
      email: "info@testhealthcare.com",
      registration_number: "REG123456",
      type: "Hospital",
      facility_type: "general",
      operating_hours: { "monday" => "9:00-17:00", "tuesday" => "9:00-17:00" },
      status: "active"
    }
  end

  # Validation Tests
  test "should be valid with valid attributes" do
    facility = HealthcareFacility.new(@valid_attributes)
    assert facility.valid?, "Facility should be valid with valid attributes"
  end

  test "should require name" do
    facility = HealthcareFacility.new(@valid_attributes.except(:name))
    assert_not facility.valid?
    assert_includes facility.errors[:name], "can't be blank"
  end

  test "should require unique name" do
    HealthcareFacility.create!(@valid_attributes)
    duplicate = HealthcareFacility.new(@valid_attributes)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "should require address" do
    facility = HealthcareFacility.new(@valid_attributes.except(:address))
    assert_not facility.valid?
    assert_includes facility.errors[:address], "can't be blank"
  end

  test "should require phone" do
    facility = HealthcareFacility.new(@valid_attributes.except(:phone))
    assert_not facility.valid?
    assert_includes facility.errors[:phone], "can't be blank"
  end

  test "should require unique phone" do
    HealthcareFacility.create!(@valid_attributes)
    duplicate = HealthcareFacility.new(@valid_attributes.merge(name: "Different Name", email: "different@email.com"))
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:phone], "has already been taken"
  end

  test "should validate phone format" do
    invalid_phones = [ "123", "abc-def-ghij", "" ]
    invalid_phones.each do |phone|
      facility = HealthcareFacility.new(@valid_attributes.merge(phone: phone))
      assert_not facility.valid?, "Phone #{phone} should be invalid"
      assert_includes facility.errors[:phone], "must be a valid phone number"
    end
  end

  test "should require email" do
    facility = HealthcareFacility.new(@valid_attributes.except(:email))
    assert_not facility.valid?
    assert_includes facility.errors[:email], "can't be blank"
  end

  test "should require unique email" do
    HealthcareFacility.create!(@valid_attributes)
    duplicate = HealthcareFacility.new(@valid_attributes.merge(name: "Different Name", phone: "+1-555-999-8888"))
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email], "has already been taken"
  end

  test "should validate email format" do
    invalid_emails = [ "invalid", "test@", "@domain.com", "test.domain.com" ]
    invalid_emails.each do |email|
      facility = HealthcareFacility.new(@valid_attributes.merge(email: email))
      assert_not facility.valid?, "Email #{email} should be invalid"
      assert_includes facility.errors[:email], "must be a valid email address"
    end
  end

  test "should require registration number" do
    facility = HealthcareFacility.new(@valid_attributes.except(:registration_number))
    assert_not facility.valid?
    assert_includes facility.errors[:registration_number], "can't be blank"
  end

  test "should require unique registration number" do
    HealthcareFacility.create!(@valid_attributes)
    duplicate = HealthcareFacility.new(@valid_attributes.merge(
      name: "Different Name",
      phone: "+1-555-999-8888",
      email: "different@email.com"
    ))
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:registration_number], "has already been taken"
  end

  test "should validate status inclusion" do
    valid_statuses = %w[active inactive suspended]
    valid_statuses.each do |status|
      facility = HealthcareFacility.new(@valid_attributes.merge(status: status))
      assert facility.valid?, "Status #{status} should be valid"
    end

    facility = HealthcareFacility.new(@valid_attributes.merge(status: "invalid_status"))
    assert_not facility.valid?
    assert_includes facility.errors[:status], "invalid_status is not a valid status"
  end

  test "should validate facility type inclusion when present" do
    # Test with base HealthcareFacility class (not Hospital subclass)
    base_attributes = @valid_attributes.except(:type).merge(type: nil)
    valid_types = %w[primary_care specialty urgent_care dental vision other]
    valid_types.each do |type|
      facility = HealthcareFacility.new(base_attributes.merge(facility_type: type))
      assert facility.valid?, "Facility type #{type} should be valid"
    end

    facility = HealthcareFacility.new(base_attributes.merge(facility_type: "invalid_type"))
    assert_not facility.valid?
    assert_includes facility.errors[:facility_type], "invalid_type is not a valid facility type"
  end

  # Callback Tests
  test "should normalize phone number on validation" do
    facility = HealthcareFacility.new(@valid_attributes.merge(phone: "+1 (555) 123-4567"))
    facility.valid?
    assert_equal "+15551234567", facility.phone
  end

  test "should normalize email on save" do
    facility = HealthcareFacility.new(@valid_attributes.merge(email: "TEST@EXAMPLE.COM"))
    facility.save!
    assert_equal "test@example.com", facility.email
  end

  # Scope Tests
  test "active scope should return only active facilities" do
    active_facility = HealthcareFacility.create!(@valid_attributes)
    inactive_facility = HealthcareFacility.create!(@valid_attributes.merge(
      name: "Inactive Facility",
      phone: "+1-555-999-8888",
      email: "inactive@test.com",
      registration_number: "REG999",
      active: false
    ))

    active_facilities = HealthcareFacility.active
    assert_includes active_facilities, active_facility
    assert_not_includes active_facilities, inactive_facility
  end

  test "hospitals scope should return only hospitals" do
    hospital = HealthcareFacility.create!(@valid_attributes.merge(type: "Hospital"))
    clinic = HealthcareFacility.create!(@valid_attributes.merge(
      name: "Test Clinic",
      phone: "+1-555-999-8888",
      email: "clinic@test.com",
      registration_number: "REG999",
      type: "Clinic",
      facility_type: "primary_care"
    ))

    hospitals = HealthcareFacility.hospitals
    assert_includes hospitals, hospital
    assert_not_includes hospitals, clinic
  end

  test "clinics scope should return only clinics" do
    hospital = HealthcareFacility.create!(@valid_attributes.merge(type: "Hospital"))
    clinic = HealthcareFacility.create!(@valid_attributes.merge(
      name: "Test Clinic",
      phone: "+1-555-999-8888",
      email: "clinic@test.com",
      registration_number: "REG999",
      type: "Clinic",
      facility_type: "primary_care"
    ))

    clinics = HealthcareFacility.clinics
    assert_includes clinics, clinic
    assert_not_includes clinics, hospital
  end

  # Instance Method Tests
  test "active? should return true for active facilities with active status" do
    facility = HealthcareFacility.create!(@valid_attributes.merge(active: true, status: "active"))
    assert facility.active?
  end

  test "active? should return false for inactive facilities" do
    facility = HealthcareFacility.create!(@valid_attributes.merge(active: false, status: "active"))
    assert_not facility.active?
  end

  test "active? should return false for facilities with non-active status" do
    facility = HealthcareFacility.create!(@valid_attributes.merge(active: true, status: "suspended"))
    assert_not facility.active?
  end

  test "hospital? should return true for hospitals" do
    facility = HealthcareFacility.create!(@valid_attributes.merge(type: "Hospital"))
    assert facility.hospital?
  end

  test "clinic? should return true for clinics" do
    facility = HealthcareFacility.create!(@valid_attributes.merge(type: "Clinic", facility_type: "primary_care"))
    assert facility.clinic?
  end

  test "display_address should format multiline address" do
    facility = HealthcareFacility.create!(@valid_attributes)
    expected = "123 Main St, Anytown, ST 12345"
    assert_equal expected, facility.display_address
  end

  test "primary_contact should return contact person when present" do
    facility = HealthcareFacility.create!(@valid_attributes.merge(
      contact_person: "John Doe",
      contact_person_phone: "+1-555-111-2222"
    ))
    expected = "John Doe (+1-555-111-2222)"
    assert_equal expected, facility.primary_contact
  end

  test "primary_contact should return phone when contact person not present" do
    facility = HealthcareFacility.create!(@valid_attributes)
    assert_equal facility.phone, facility.primary_contact
  end
end
