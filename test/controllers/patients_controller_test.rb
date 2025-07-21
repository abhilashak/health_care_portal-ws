# frozen_string_literal: true

require "test_helper"

class PatientsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @patient = patients(:adult_patient)
    @valid_attributes = {
      first_name: "Emma",
      last_name: "Wilson",
      date_of_birth: 25.years.ago.to_date,
      email: "emma.wilson@example.com",
      phone: "+1-555-345-6789",
      address: "789 Patient Ave\nHealthy City, HC 98765",
      emergency_contact_name: "John Wilson",
      emergency_contact_phone: "+1-555-999-8888",
      insurance_provider: "HealthCare Plus",
      insurance_policy_number: "HP123456789",
      medical_history: "No known allergies. Previous surgery in 2020.",
      current_medications: [ "Vitamin D", "Multivitamin" ]
    }
    @invalid_attributes = {
      first_name: "",
      last_name: "",
      date_of_birth: nil,
      email: "invalid-email",
      phone: "invalid-phone"
    }
  end

  # Index Tests
  test "should get index" do
    get patients_url
    assert_response :success
    assert_not_nil assigns(:patients)
    assert_includes @response.body, @patient.full_name
  end

  test "should get index with search parameter" do
    get patients_url, params: { search: @patient.first_name }
    assert_response :success
    assert_includes @response.body, @patient.full_name
  end

  test "should get index with email search" do
    get patients_url, params: { email: @patient.email }
    assert_response :success
    assert_includes @response.body, @patient.full_name
  end

  test "should get index filtered by age group" do
    get patients_url, params: { age_group: "adult" }
    assert_response :success
  end

  test "should get index with pagination" do
    get patients_url, params: { page: 1 }
    assert_response :success
  end

  # Show Tests
  test "should show patient" do
    get patient_url(@patient)
    assert_response :success
    assert_includes @response.body, @patient.full_name
    assert_includes @response.body, @patient.email
  end

  test "should show patient with appointments" do
    get patient_url(@patient)
    assert_response :success
    # Should display upcoming appointments
    @patient.appointments.upcoming.each do |appointment|
      assert_includes @response.body, appointment.doctor.full_name
    end
  end

  test "should show patient age and category" do
    get patient_url(@patient)
    assert_response :success
    assert_includes @response.body, @patient.age.to_s
    if @patient.adult?
      assert_includes @response.body, "Adult"
    elsif @patient.minor?
      assert_includes @response.body, "Minor"
    elsif @patient.senior?
      assert_includes @response.body, "Senior"
    end
  end

  test "should return 404 for non-existent patient" do
    assert_raises(ActiveRecord::RecordNotFound) do
      get patient_url(id: 99999)
    end
  end

  # New Tests
  test "should get new" do
    get new_patient_url
    assert_response :success
    assert_select "form[action=?]", patients_path
  end

  # Create Tests
  test "should create patient with valid attributes" do
    assert_difference("Patient.count") do
      post patients_url, params: { patient: @valid_attributes }
    end

    patient = Patient.last
    assert_redirected_to patient_url(patient)
    assert_equal @valid_attributes[:first_name], patient.first_name
    assert_equal @valid_attributes[:email], patient.email
  end

  test "should not create patient with invalid attributes" do
    assert_no_difference("Patient.count") do
      post patients_url, params: { patient: @invalid_attributes }
    end

    assert_response :unprocessable_entity
    assert_select ".error", text: /can't be blank/
  end

  test "should not create patient with duplicate email" do
    duplicate_attributes = @valid_attributes.merge(email: @patient.email)

    assert_no_difference("Patient.count") do
      post patients_url, params: { patient: duplicate_attributes }
    end

    assert_response :unprocessable_entity
    assert_select ".error", text: /has already been taken/
  end

  test "should not create patient with future birth date" do
    future_attributes = @valid_attributes.merge(date_of_birth: 1.day.from_now.to_date)

    assert_no_difference("Patient.count") do
      post patients_url, params: { patient: future_attributes }
    end

    assert_response :unprocessable_entity
    assert_select ".error", text: /cannot be in the future/
  end

  # Edit Tests
  test "should get edit" do
    get edit_patient_url(@patient)
    assert_response :success
    assert_select "form[action=?]", patient_path(@patient)
    assert_select "input[value=?]", @patient.first_name
  end

  # Update Tests
  test "should update patient with valid attributes" do
    new_phone = "+1-555-999-0000"
    patch patient_url(@patient), params: {
      patient: {
        phone: new_phone,
        insurance_provider: "New Insurance Co"
      }
    }

    assert_redirected_to patient_url(@patient)
    @patient.reload
    assert_equal new_phone, @patient.phone
    assert_equal "New Insurance Co", @patient.insurance_provider
  end

  test "should not update patient with invalid attributes" do
    original_email = @patient.email
    patch patient_url(@patient), params: {
      patient: {
        email: "invalid-email",
        date_of_birth: 1.day.from_now.to_date
      }
    }

    assert_response :unprocessable_entity
    @patient.reload
    assert_equal original_email, @patient.email
  end

  test "should not update patient with duplicate email" do
    other_patient = patients(:senior_patient)
    original_email = @patient.email

    patch patient_url(@patient), params: {
      patient: { email: other_patient.email }
    }

    assert_response :unprocessable_entity
    @patient.reload
    assert_equal original_email, @patient.email
  end

  # Destroy Tests
  test "should destroy patient" do
    assert_difference("Patient.count", -1) do
      delete patient_url(@patient)
    end

    assert_redirected_to patients_url
  end

  test "should not destroy patient with upcoming appointments" do
    # Create an upcoming appointment
    appointment = Appointment.create!(
      doctor: doctors(:cardiologist),
      patient: @patient,
      appointment_date: 2.days.from_now,
      status: "scheduled",
      duration_minutes: 30
    )

    assert_no_difference("Patient.count") do
      delete patient_url(@patient)
    end

    assert_redirected_to patient_url(@patient)
    assert_match /cannot be deleted.*upcoming appointments/, flash[:alert]
  end

  # Custom Endpoints Tests
  test "should get patient appointments" do
    get patient_appointments_url(@patient)
    assert_response :success
    assert_not_nil assigns(:appointments)
  end

  test "should get patient upcoming appointments" do
    get patient_upcoming_appointments_url(@patient)
    assert_response :success
    assert_not_nil assigns(:upcoming_appointments)
  end

  test "should get patient medical history" do
    get patient_medical_history_url(@patient)
    assert_response :success
    assert_not_nil assigns(:medical_history)
  end

  test "should get patient doctors" do
    get patient_doctors_url(@patient)
    assert_response :success
    assert_not_nil assigns(:doctors)
  end

  test "should update patient medical history" do
    new_history = "Updated medical history with recent checkup results."
    patch patient_update_medical_history_url(@patient), params: {
      medical_history: new_history
    }

    assert_redirected_to patient_url(@patient)
    @patient.reload
    assert_includes @patient.medical_history, new_history
  end

  test "should add medication to patient" do
    new_medication = "Aspirin 81mg"
    post patient_add_medication_url(@patient), params: { medication: new_medication }

    assert_redirected_to patient_url(@patient)
    @patient.reload
    assert_includes @patient.current_medications, new_medication
  end

  test "should remove medication from patient" do
    medication_to_remove = @patient.current_medications.first
    delete patient_remove_medication_url(@patient), params: { medication: medication_to_remove }

    assert_redirected_to patient_url(@patient)
    @patient.reload
    assert_not_includes @patient.current_medications, medication_to_remove
  end

  # Search and Filter Tests
  test "should search patients by name" do
    get patients_url, params: { search: @patient.first_name }
    assert_response :success
    assert_includes @response.body, @patient.full_name
  end

  test "should search patients by email" do
    get patients_url, params: { search: @patient.email }
    assert_response :success
    assert_includes @response.body, @patient.full_name
  end

  test "should filter patients by age group" do
    get patients_url, params: { age_group: "adult" }
    assert_response :success
  end

  test "should filter patients by birth year" do
    birth_year = @patient.date_of_birth.year
    get patients_url, params: { birth_year: birth_year }
    assert_response :success
  end

  test "should filter patients by insurance provider" do
    get patients_url, params: { insurance: @patient.insurance_provider }
    assert_response :success
  end

  test "should filter patients with recent appointments" do
    get patients_url, params: { recent_appointments: true }
    assert_response :success
  end

  # API/JSON Response Tests
  test "should get index as JSON" do
    get patients_url, as: :json
    assert_response :success

    json_response = JSON.parse(@response.body)
    assert json_response.is_a?(Array)
    assert json_response.any? { |p| p["first_name"] == @patient.first_name }
  end

  test "should show patient as JSON" do
    get patient_url(@patient), as: :json
    assert_response :success

    json_response = JSON.parse(@response.body)
    assert_equal @patient.first_name, json_response["first_name"]
    assert_equal @patient.email, json_response["email"]
    assert_equal @patient.age, json_response["age"]
  end

  test "should create patient via JSON" do
    assert_difference("Patient.count") do
      post patients_url, params: { patient: @valid_attributes }, as: :json
    end

    assert_response :created
    json_response = JSON.parse(@response.body)
    assert_equal @valid_attributes[:first_name], json_response["first_name"]
  end

  test "should update patient via JSON" do
    patch patient_url(@patient), params: {
      patient: { phone: "+1-555-updated-phone" }
    }, as: :json

    assert_response :success
    @patient.reload
    assert_equal "+1-555-updated-phone", @patient.phone
  end

  test "should destroy patient via JSON" do
    assert_difference("Patient.count", -1) do
      delete patient_url(@patient), as: :json
    end

    assert_response :no_content
  end

  test "should get patient appointments as JSON" do
    get patient_appointments_url(@patient), as: :json
    assert_response :success

    json_response = JSON.parse(@response.body)
    assert json_response.is_a?(Array)
  end

  # Appointment Booking Tests
  test "should book appointment for patient" do
    doctor = doctors(:cardiologist)
    appointment_params = {
      doctor_id: doctor.id,
      appointment_date: 2.days.from_now.beginning_of_hour,
      duration_minutes: 30,
      notes: "Annual physical exam"
    }

    assert_difference("Appointment.count") do
      post patient_book_appointment_url(@patient), params: { appointment: appointment_params }
    end

    assert_redirected_to patient_url(@patient)
    appointment = Appointment.last
    assert_equal @patient, appointment.patient
    assert_equal doctor, appointment.doctor
  end

  test "should cancel appointment for patient" do
    appointment = appointments(:scheduled_appointment)
    appointment.update!(patient: @patient)

    patch patient_cancel_appointment_url(@patient, appointment)

    assert_redirected_to patient_url(@patient)
    appointment.reload
    assert_equal "cancelled", appointment.status
  end

  test "should reschedule appointment for patient" do
    appointment = appointments(:scheduled_appointment)
    appointment.update!(patient: @patient)
    new_date = 5.days.from_now.beginning_of_hour

    patch patient_reschedule_appointment_url(@patient, appointment), params: {
      appointment: { appointment_date: new_date }
    }

    assert_redirected_to patient_url(@patient)
    appointment.reload
    assert_equal new_date, appointment.appointment_date
  end

  # Privacy and Security Tests
  test "should not show sensitive patient data to unauthorized users" do
    # This test assumes authorization will be implemented
    # get patient_url(@patient)
    # assert_response :forbidden
    # assert_not_includes @response.body, @patient.insurance_policy_number
  end

  test "should mask sensitive information in JSON responses" do
    get patient_url(@patient), as: :json
    assert_response :success

    json_response = JSON.parse(@response.body)
    # Should not include full insurance policy number
    assert_not_equal @patient.insurance_policy_number, json_response["insurance_policy_number"]
  end

  # Error Handling Tests
  test "should handle invalid JSON requests gracefully" do
    post patients_url, params: "invalid json", as: :json
    assert_response :bad_request
  end

  test "should require authentication for create actions" do
    # This test assumes authentication will be implemented
    # post patients_url, params: { patient: @valid_attributes }
    # assert_redirected_to login_url
  end

  test "should require proper privileges for destroy actions" do
    # This test assumes authorization will be implemented
    # delete patient_url(@patient)
    # assert_response :forbidden
  end

  # Data Validation Tests
  test "should validate email format" do
    post patients_url, params: {
      patient: @valid_attributes.merge(email: "invalid.email.format")
    }

    assert_response :unprocessable_entity
    assert_select ".error", text: /must be a valid email address/
  end

  test "should validate phone format" do
    post patients_url, params: {
      patient: @valid_attributes.merge(phone: "123")
    }

    assert_response :unprocessable_entity
    assert_select ".error", text: /must be a valid phone number/
  end

  test "should validate reasonable age" do
    post patients_url, params: {
      patient: @valid_attributes.merge(date_of_birth: 200.years.ago.to_date)
    }

    assert_response :unprocessable_entity
    assert_select ".error", text: /not a reasonable age/
  end
end
