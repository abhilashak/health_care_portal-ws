# frozen_string_literal: true

require "test_helper"

class DoctorsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @doctor = doctors(:cardiologist)
    @hospital = healthcare_facilities(:general_hospital)
    @clinic = healthcare_facilities(:family_clinic)
    @valid_attributes = {
      first_name: "Alice",
      last_name: "Johnson",
      specialization: "Dermatology",
      hospital_id: @hospital.id,
      clinic_id: nil
    }
    @invalid_attributes = {
      first_name: "",
      last_name: "",
      specialization: ""
    }
  end

  # Index Tests
  test "should get index" do
    get doctors_url
    assert_response :success
    assert_includes @response.body, @doctor.full_name
  end

  test "should get index with search parameter" do
    get doctors_url, params: { search: @doctor.first_name }
    assert_response :success
    assert_includes @response.body, @doctor.full_name
  end

  test "should get index filtered by specialization" do
    get doctors_url, params: { specialization: @doctor.specialization }
    assert_response :success
  end

  test "should get index filtered by hospital" do
    get doctors_url, params: { hospital_id: @doctor.hospital_id }
    assert_response :success
  end

  test "should get index filtered by clinic" do
    get doctors_url, params: { clinic_id: @doctor.clinic_id }
    assert_response :success
  end

  test "should get index with pagination" do
    get doctors_url, params: { page: 1 }
    assert_response :success
  end

  # Show Tests
  test "should show doctor" do
    get doctor_url(@doctor)
    assert_response :success
    assert_includes @response.body, @doctor.full_name
    assert_includes @response.body, @doctor.specialization
  end

  test "should show doctor with appointments" do
    get doctor_url(@doctor)
    assert_response :success
    # Should display upcoming appointments
    @doctor.appointments.upcoming.each do |appointment|
      assert_includes @response.body, appointment.patient.full_name
    end
  end

  test "should show doctor with facilities" do
    get doctor_url(@doctor)
    assert_response :success
    if @doctor.hospital
      assert_includes @response.body, @doctor.hospital.name
    end
    if @doctor.clinic
      assert_includes @response.body, @doctor.clinic.name
    end
  end

  test "should return 404 for non-existent doctor" do
    assert_raises(ActiveRecord::RecordNotFound) do
      get doctor_url(id: 99999)
    end
  end

  # New Tests
  test "should get new" do
    get new_doctor_url
    assert_response :success
    assert_select "form[action=?]", doctors_path
  end

  # Create Tests
  test "should create doctor with valid attributes" do
    assert_difference("Doctor.count") do
      post doctors_url, params: { doctor: @valid_attributes }
    end

    doctor = Doctor.last
    assert_redirected_to doctor_url(doctor)
    assert_equal @valid_attributes[:first_name], doctor.first_name
    assert_equal @valid_attributes[:specialization], doctor.specialization
  end

  test "should create doctor with hospital only" do
    attributes = @valid_attributes.merge(clinic_id: nil)

    assert_difference("Doctor.count") do
      post doctors_url, params: { doctor: attributes }
    end

    doctor = Doctor.last
    assert_equal @hospital, doctor.hospital
    assert_nil doctor.clinic
  end

  test "should create doctor with clinic only" do
    attributes = @valid_attributes.merge(hospital_id: nil, clinic_id: @clinic.id)

    assert_difference("Doctor.count") do
      post doctors_url, params: { doctor: attributes }
    end

    doctor = Doctor.last
    assert_nil doctor.hospital
    assert_equal @clinic, doctor.clinic
  end

  test "should create doctor with both hospital and clinic" do
    attributes = @valid_attributes.merge(clinic_id: @clinic.id)

    assert_difference("Doctor.count") do
      post doctors_url, params: { doctor: attributes }
    end

    doctor = Doctor.last
    assert_equal @hospital, doctor.hospital
    assert_equal @clinic, doctor.clinic
  end

  test "should not create doctor with invalid attributes" do
    assert_no_difference("Doctor.count") do
      post doctors_url, params: { doctor: @invalid_attributes }
    end

    assert_response :unprocessable_entity
    assert_select ".error", text: /can't be blank/
  end

  test "should not create doctor without hospital or clinic" do
    attributes = @valid_attributes.merge(hospital_id: nil, clinic_id: nil)

    assert_no_difference("Doctor.count") do
      assert_raises(ActiveRecord::StatementInvalid) do
        post doctors_url, params: { doctor: attributes }
      end
    end
  end

  # Edit Tests
  test "should get edit" do
    get edit_doctor_url(@doctor)
    assert_response :success
    assert_select "form[action=?]", doctor_path(@doctor)
    assert_select "input[value=?]", @doctor.first_name
  end

  # Update Tests
  test "should update doctor with valid attributes" do
    new_specialization = "Neurology"
    patch doctor_url(@doctor), params: {
      doctor: {
        specialization: new_specialization
      }
    }

    assert_redirected_to doctor_url(@doctor)
    @doctor.reload
    assert_equal new_specialization, @doctor.specialization
  end

  test "should not update doctor with invalid attributes" do
    original_name = @doctor.first_name
    patch doctor_url(@doctor), params: {
      doctor: {
        first_name: ""
      }
    }

    assert_response :unprocessable_entity
    @doctor.reload
    assert_equal original_name, @doctor.first_name
  end

  test "should update doctor facility associations" do
    patch doctor_url(@doctor), params: {
      doctor: {
        hospital_id: nil,
        clinic_id: @clinic.id
      }
    }

    assert_redirected_to doctor_url(@doctor)
    @doctor.reload
    assert_nil @doctor.hospital
    assert_equal @clinic, @doctor.clinic
  end

  # Destroy Tests
  test "should destroy doctor" do
    # Cancel any upcoming appointments to allow deletion
    @doctor.appointments.upcoming.update_all(status: "cancelled")

    assert_difference("Doctor.count", -1) do
      delete doctor_url(@doctor)
    end

    assert_redirected_to doctors_url
  end

  test "should not destroy doctor with upcoming appointments" do
    # Create an upcoming appointment
    appointment = Appointment.create!(
      doctor: @doctor,
      patient: patients(:adult_patient),
      appointment_date: 2.days.from_now,
      status: "scheduled",
      duration_minutes: 30
    )

    assert_no_difference("Doctor.count") do
      delete doctor_url(@doctor)
    end

    assert_redirected_to doctor_url(@doctor)
    assert_match /cannot be deleted.*upcoming appointments/, flash[:alert]
  end

  # Custom Endpoints Tests
  test "should get doctor appointments" do
    get appointments_doctor_url(@doctor)
    assert_response :success
  end

  test "should get doctor upcoming appointments" do
    get upcoming_appointments_doctor_url(@doctor)
    assert_response :success
  end

  test "should get doctor past appointments" do
    get past_appointments_doctor_url(@doctor)
    assert_response :success
  end

  test "should get doctor schedule" do
    get schedule_doctor_url(@doctor), params: { date: Date.current }
    assert_response :success
    assert_not_nil assigns(:schedule)
  end

  test "should get doctor availability" do
    get availability_doctor_url(@doctor), params: {
      start_date: Date.current,
      end_date: 1.week.from_now
    }
    assert_response :success
    assert_not_nil assigns(:availability)
  end

  test "should get doctor statistics" do
    get statistics_doctor_url(@doctor)
    assert_response :success
  end

  test "should get doctor patients" do
    get patients_doctor_url(@doctor)
    assert_response :success
  end

  # Search and Filter Tests
  test "should search doctors by name" do
    get doctors_url, params: { search: @doctor.first_name }
    assert_response :success
    assert_includes @response.body, @doctor.full_name
  end

  test "should search doctors by specialization" do
    get doctors_url, params: { search: @doctor.specialization }
    assert_response :success
    assert_includes @response.body, @doctor.full_name
  end

  test "should filter doctors by experience" do
    get doctors_url, params: { min_experience: 5 }
    assert_response :success
  end

  test "should filter doctors by availability" do
    get doctors_url, params: { available_date: Date.current }
    assert_response :success
  end

  test "should filter doctors working at hospitals" do
    get doctors_url, params: { works_at: "hospital" }
    assert_response :success
  end

  test "should filter doctors working at clinics" do
    get doctors_url, params: { works_at: "clinic" }
    assert_response :success
  end

  # API/JSON Response Tests
  test "should get index as JSON" do
    get doctors_url, as: :json
    assert_response :success

    json_response = JSON.parse(@response.body)
    assert json_response.is_a?(Array)
    assert json_response.any? { |d| d["first_name"] == @doctor.first_name }
  end

  test "should show doctor as JSON" do
    get doctor_url(@doctor), as: :json
    assert_response :success

    json_response = JSON.parse(@response.body)
    assert_equal @doctor.first_name, json_response["first_name"]
    assert_equal @doctor.specialization, json_response["specialization"]
  end

  test "should create doctor via JSON" do
    assert_difference("Doctor.count") do
      post doctors_url, params: { doctor: @valid_attributes }, as: :json
    end

    assert_response :created
    json_response = JSON.parse(@response.body)
    assert_equal @valid_attributes[:first_name], json_response["first_name"]
  end

  test "should update doctor via JSON" do
    patch doctor_url(@doctor), params: {
      doctor: { specialization: "Updated via JSON" }
    }, as: :json

    assert_response :success
    @doctor.reload
    assert_equal "Updated via JSON", @doctor.specialization
  end

  test "should destroy doctor via JSON" do
    # Cancel any upcoming appointments to allow deletion
    @doctor.appointments.upcoming.update_all(status: "cancelled")

    assert_difference("Doctor.count", -1) do
      delete doctor_url(@doctor), as: :json
    end

    assert_response :no_content
  end

  test "should get doctor appointments as JSON" do
    get appointments_doctor_url(@doctor), as: :json
    assert_response :success

    json_response = JSON.parse(@response.body)
    assert json_response.is_a?(Array)
  end

  # Appointment Management Tests
  test "should book appointment for doctor" do
    patient = patients(:adult_patient)
    appointment_params = {
      patient_id: patient.id,
      appointment_date: 2.days.from_now.beginning_of_hour,
      duration_minutes: 30,
      notes: "Regular checkup"
    }

    assert_difference("Appointment.count") do
      post book_appointment_doctor_url(@doctor), params: { appointment: appointment_params }
    end

    assert_redirected_to doctor_url(@doctor)
    appointment = Appointment.last
    assert_equal @doctor, appointment.doctor
    assert_equal patient, appointment.patient
  end

  test "should cancel appointment for doctor" do
    appointment = appointments(:scheduled_appointment)
    appointment.update!(doctor: @doctor)

    patch cancel_appointment_doctor_url(@doctor), params: { appointment_id: appointment.id }

    assert_redirected_to doctor_url(@doctor)
    appointment.reload
    assert_equal "cancelled", appointment.status
  end

  # Error Handling Tests
  test "should handle invalid JSON requests gracefully" do
    post doctors_url, params: "invalid json", as: :json
    assert_response :bad_request
  end

  test "should require authentication for create actions" do
    # This test assumes authentication will be implemented
    # post doctors_url, params: { doctor: @valid_attributes }
    # assert_redirected_to login_url
  end

  test "should require proper privileges for destroy actions" do
    # This test assumes authorization will be implemented
    # delete doctor_url(@doctor)
    # assert_response :forbidden
  end
end
