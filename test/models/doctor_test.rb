# frozen_string_literal: true

require_relative "application_model_test_case"

class DoctorTest < ApplicationModelTestCase
  # Validation Tests
  test "should be valid with valid attributes" do
    doctor = doctors(:cardiologist)
    assert doctor.valid?, "Doctor should be valid with valid attributes"
  end

  test "should require first_name" do
    doctor = doctors(:cardiologist)
    doctor.first_name = nil
    assert_not doctor.valid?
    assert_includes doctor.errors[:first_name], "can't be blank"
  end

  test "should require last_name" do
    doctor = doctors(:cardiologist)
    doctor.last_name = nil
    assert_not doctor.valid?
    assert_includes doctor.errors[:last_name], "can't be blank"
  end

  test "should require specialization" do
    doctor = doctors(:cardiologist)
    doctor.specialization = nil
    assert_not doctor.valid?
    assert_includes doctor.errors[:specialization], "can't be blank"
  end

  # Association Tests
  test "should belong to hospital when hospital_id is present" do
    doctor = doctors(:cardiologist)
    assert_equal healthcare_facilities(:general_hospital), doctor.hospital
  end

  test "should belong to clinic when clinic_id is present" do
    doctor = doctors(:family_doctor)
    assert_equal healthcare_facilities(:family_clinic), doctor.clinic
  end

  test "should belong to both hospital and clinic when both ids are present" do
    doctor = doctors(:dual_doctor)
    assert_equal healthcare_facilities(:teaching_hospital), doctor.hospital
    assert_equal healthcare_facilities(:family_clinic), doctor.clinic
  end

  test "hospital association should be optional" do
    doctor = doctors(:family_doctor)
    assert_nil doctor.hospital
    assert doctor.valid?
  end

  test "clinic association should be optional" do
    doctor = doctors(:cardiologist)
    assert_nil doctor.clinic
    assert doctor.valid?
  end

  # Scope Tests
  test "by_specialization scope should filter by specialization" do
    cardiologists = Doctor.by_specialization("Cardiology")
    assert_includes cardiologists, doctors(:cardiologist)
    assert_not_includes cardiologists, doctors(:neurologist)
  end

  test "at_hospital scope should filter by hospital" do
    hospital_doctors = Doctor.at_hospital(healthcare_facilities(:general_hospital).id)
    assert_includes hospital_doctors, doctors(:cardiologist)
    assert_includes hospital_doctors, doctors(:neurologist)
    assert_not_includes hospital_doctors, doctors(:family_doctor)
  end

  test "at_clinic scope should filter by clinic" do
    clinic_doctors = Doctor.at_clinic(healthcare_facilities(:family_clinic).id)
    assert_includes clinic_doctors, doctors(:family_doctor)
    assert_includes clinic_doctors, doctors(:dual_doctor)
    assert_not_includes clinic_doctors, doctors(:cardiologist)
  end

  test "search_by_name scope should find doctors by first or last name" do
    results = Doctor.search_by_name("John")
    assert_includes results, doctors(:cardiologist)

    results = Doctor.search_by_name("Smith")
    assert_includes results, doctors(:cardiologist)

    results = Doctor.search_by_name("xyz")
    assert_empty results
  end

  # Callback Tests
  test "should normalize names on validation" do
    doctor = Doctor.new(
      first_name: "  john  ",
      last_name: "  smith  ",
      specialization: "  cardiology  ",
      hospital_id: healthcare_facilities(:general_hospital).id
    )
    doctor.valid?
    assert_equal "John", doctor.first_name
    assert_equal "Smith", doctor.last_name
    assert_equal "Cardiology", doctor.specialization
  end

  # Instance Method Tests
  test "full_name should return first and last name" do
    doctor = doctors(:cardiologist)
    assert_equal "John Smith", doctor.full_name
  end

  test "display_name should return name with Dr. prefix" do
    doctor = doctors(:cardiologist)
    assert_equal "Dr. John Smith", doctor.display_name
  end

  test "facilities should return array of associated facilities" do
    doctor = doctors(:dual_doctor)
    facilities = doctor.facilities
    assert_includes facilities, healthcare_facilities(:teaching_hospital)
    assert_includes facilities, healthcare_facilities(:family_clinic)
    assert_equal 2, facilities.length
  end

  test "facilities should return only hospital when only hospital is present" do
    doctor = doctors(:cardiologist)
    facilities = doctor.facilities
    assert_includes facilities, healthcare_facilities(:general_hospital)
    assert_equal 1, facilities.length
  end

  test "facilities should return only clinic when only clinic is present" do
    doctor = doctors(:family_doctor)
    facilities = doctor.facilities
    assert_includes facilities, healthcare_facilities(:family_clinic)
    assert_equal 1, facilities.length
  end

  test "primary_facility should return hospital when both are present" do
    doctor = doctors(:dual_doctor)
    assert_equal healthcare_facilities(:teaching_hospital), doctor.primary_facility
  end

  test "primary_facility should return hospital when only hospital is present" do
    doctor = doctors(:cardiologist)
    assert_equal healthcare_facilities(:general_hospital), doctor.primary_facility
  end

  test "primary_facility should return clinic when only clinic is present" do
    doctor = doctors(:family_doctor)
    assert_equal healthcare_facilities(:family_clinic), doctor.primary_facility
  end

  test "works_at_hospital? should return true when hospital_id is present" do
    doctor = doctors(:cardiologist)
    assert doctor.works_at_hospital?
  end

  test "works_at_hospital? should return false when hospital_id is not present" do
    doctor = doctors(:family_doctor)
    assert_not doctor.works_at_hospital?
  end

  test "works_at_clinic? should return true when clinic_id is present" do
    doctor = doctors(:family_doctor)
    assert doctor.works_at_clinic?
  end

  test "works_at_clinic? should return false when clinic_id is not present" do
    doctor = doctors(:cardiologist)
    assert_not doctor.works_at_clinic?
  end

  test "works_at_both? should return true when both hospital_id and clinic_id are present" do
    doctor = doctors(:dual_doctor)
    assert doctor.works_at_both?
  end

  test "works_at_both? should return false when only hospital_id is present" do
    doctor = doctors(:cardiologist)
    assert_not doctor.works_at_both?
  end

  test "works_at_both? should return false when only clinic_id is present" do
    doctor = doctors(:family_doctor)
    assert_not doctor.works_at_both?
  end

  # Database Constraint Tests
  test "should enforce foreign key constraint for hospital" do
    assert_raises(ActiveRecord::InvalidForeignKey) do
      Doctor.create!(
        first_name: "Test",
        last_name: "Doctor",
        specialization: "Test Specialty",
        hospital_id: 99999
      )
    end
  end

  test "should enforce foreign key constraint for clinic" do
    assert_raises(ActiveRecord::InvalidForeignKey) do
      Doctor.create!(
        first_name: "Test",
        last_name: "Doctor",
        specialization: "Test Specialty",
        clinic_id: 99999
      )
    end
  end

  test "should enforce check constraint requiring at least one facility" do
    assert_raises(ActiveRecord::StatementInvalid) do
      Doctor.create!(
        first_name: "Test",
        last_name: "Doctor",
        specialization: "Test Specialty",
        hospital_id: nil,
        clinic_id: nil
      )
    end
  end
end
