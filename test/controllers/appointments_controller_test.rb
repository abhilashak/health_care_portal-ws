# frozen_string_literal: true

require "test_helper"

class AppointmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @appointment = appointments(:scheduled_appointment)
    @doctor = doctors(:cardiologist)
    @patient = patients(:adult_patient)
    @valid_attributes = {
      doctor_id: @doctor.id,
      patient_id: @patient.id,
      appointment_date: 3.days.from_now.beginning_of_hour,
      duration_minutes: 45,
      status: "scheduled",
      notes: "Regular checkup appointment",
      appointment_type: "consultation"
    }
    @invalid_attributes = {
      doctor_id: nil,
      patient_id: nil,
      appointment_date: nil,
      duration_minutes: -10,
      status: "invalid_status"
    }
  end

  # Index Tests
  test "should get index" do
    get appointments_url
    assert_response :success
    assert_not_nil assigns(:appointments)
    assert_includes @response.body, @appointment.doctor.full_name
  end

  test "should get index with date filter" do
    get appointments_url, params: { date: Date.current }
    assert_response :success
  end

  test "should get index filtered by status" do
    get appointments_url, params: { status: "scheduled" }
    assert_response :success
  end

  test "should get index filtered by doctor" do
    get appointments_url, params: { doctor_id: @appointment.doctor_id }
    assert_response :success
  end

  test "should get index filtered by patient" do
    get appointments_url, params: { patient_id: @appointment.patient_id }
    assert_response :success
  end

  test "should get index with date range" do
    get appointments_url, params: { 
      start_date: Date.current,
      end_date: 1.week.from_now
    }
    assert_response :success
  end

  # Show Tests
  test "should show appointment" do
    get appointment_url(@appointment)
    assert_response :success
    assert_includes @response.body, @appointment.doctor.full_name
    assert_includes @response.body, @appointment.patient.full_name
  end

  test "should show appointment with formatted date and time" do
    get appointment_url(@appointment)
    assert_response :success
    assert_includes @response.body, @appointment.formatted_date
    assert_includes @response.body, @appointment.formatted_time
  end

  test "should show appointment duration" do
    get appointment_url(@appointment)
    assert_response :success
    assert_includes @response.body, "#{@appointment.duration_minutes} minutes"
  end

  test "should return 404 for non-existent appointment" do
    assert_raises(ActiveRecord::RecordNotFound) do
      get appointment_url(id: 99999)
    end
  end

  # New Tests
  test "should get new" do
    get new_appointment_url
    assert_response :success
    assert_select "form[action=?]", appointments_path
  end

  test "should get new with doctor preselected" do
    get new_appointment_url, params: { doctor_id: @doctor.id }
    assert_response :success
    assert_select "select[name='appointment[doctor_id]'] option[selected][value='#{@doctor.id}']"
  end

  test "should get new with patient preselected" do
    get new_appointment_url, params: { patient_id: @patient.id }
    assert_response :success
    assert_select "select[name='appointment[patient_id]'] option[selected][value='#{@patient.id}']"
  end

  # Create Tests
  test "should create appointment with valid attributes" do
    assert_difference("Appointment.count") do
      post appointments_url, params: { appointment: @valid_attributes }
    end

    appointment = Appointment.last
    assert_redirected_to appointment_url(appointment)
    assert_equal @valid_attributes[:doctor_id], appointment.doctor_id
    assert_equal @valid_attributes[:patient_id], appointment.patient_id
    assert_equal "scheduled", appointment.status
  end

  test "should not create appointment with invalid attributes" do
    assert_no_difference("Appointment.count") do
      post appointments_url, params: { appointment: @invalid_attributes }
    end

    assert_response :unprocessable_entity
    assert_select ".error", text: /can't be blank/
  end

  test "should not create appointment in the past" do
    past_attributes = @valid_attributes.merge(appointment_date: 1.day.ago)
    
    assert_no_difference("Appointment.count") do
      post appointments_url, params: { appointment: past_attributes }
    end

    assert_response :unprocessable_entity
    assert_select ".error", text: /cannot be in the past/
  end

  test "should not create overlapping appointment" do
    # Create an existing appointment
    existing_appointment = Appointment.create!(
      doctor: @doctor,
      patient: patients(:senior_patient),
      appointment_date: @valid_attributes[:appointment_date],
      duration_minutes: 30,
      status: 'scheduled'
    )

    overlapping_attributes = @valid_attributes.merge(
      appointment_date: existing_appointment.appointment_date + 15.minutes
    )
    
    assert_no_difference("Appointment.count") do
      post appointments_url, params: { appointment: overlapping_attributes }
    end

    assert_response :unprocessable_entity
    assert_select ".error", text: /conflicts with doctor's existing appointment/
  end

  # Edit Tests
  test "should get edit" do
    get edit_appointment_url(@appointment)
    assert_response :success
    assert_select "form[action=?]", appointment_path(@appointment)
  end

  test "should not allow editing past appointments" do
    past_appointment = appointments(:completed_appointment)
    past_appointment.update!(appointment_date: 1.day.ago, status: 'completed')
    
    get edit_appointment_url(past_appointment)
    assert_redirected_to appointment_url(past_appointment)
    assert_match /cannot edit past appointments/, flash[:alert]
  end

  # Update Tests
  test "should update appointment with valid attributes" do
    new_date = 5.days.from_now.beginning_of_hour
    patch appointment_url(@appointment), params: { 
      appointment: { 
        appointment_date: new_date,
        duration_minutes: 60,
        notes: "Updated notes"
      } 
    }
    
    assert_redirected_to appointment_url(@appointment)
    @appointment.reload
    assert_equal new_date, @appointment.appointment_date
    assert_equal 60, @appointment.duration_minutes
    assert_equal "Updated notes", @appointment.notes
  end

  test "should not update appointment with invalid attributes" do
    original_date = @appointment.appointment_date
    patch appointment_url(@appointment), params: { 
      appointment: { 
        appointment_date: nil,
        duration_minutes: -30
      } 
    }
    
    assert_response :unprocessable_entity
    @appointment.reload
    assert_equal original_date, @appointment.appointment_date
  end

  test "should update appointment status" do
    patch appointment_url(@appointment), params: { 
      appointment: { status: "confirmed" } 
    }
    
    assert_redirected_to appointment_url(@appointment)
    @appointment.reload
    assert_equal "confirmed", @appointment.status
  end

  # Destroy Tests
  test "should destroy appointment" do
    assert_difference("Appointment.count", -1) do
      delete appointment_url(@appointment)
    end

    assert_redirected_to appointments_url
  end

  test "should not destroy completed appointment" do
    completed_appointment = appointments(:completed_appointment)
    completed_appointment.update!(status: 'completed')
    
    assert_no_difference("Appointment.count") do
      delete appointment_url(completed_appointment)
    end

    assert_redirected_to appointment_url(completed_appointment)
    assert_match /cannot delete completed appointments/, flash[:alert]
  end

  # Status Management Tests
  test "should confirm appointment" do
    patch confirm_appointment_url(@appointment)
    
    assert_redirected_to appointment_url(@appointment)
    @appointment.reload
    assert_equal "confirmed", @appointment.status
  end

  test "should cancel appointment" do
    patch cancel_appointment_url(@appointment)
    
    assert_redirected_to appointment_url(@appointment)
    @appointment.reload
    assert_equal "cancelled", @appointment.status
  end

  test "should complete appointment" do
    @appointment.update!(status: 'confirmed')
    patch complete_appointment_url(@appointment)
    
    assert_redirected_to appointment_url(@appointment)
    @appointment.reload
    assert_equal "completed", @appointment.status
  end

  test "should reschedule appointment" do
    new_date = 1.week.from_now.beginning_of_hour
    patch reschedule_appointment_url(@appointment), params: {
      appointment: { appointment_date: new_date }
    }
    
    assert_redirected_to appointment_url(@appointment)
    @appointment.reload
    assert_equal new_date, @appointment.appointment_date
    assert_equal "scheduled", @appointment.status
  end

  # Custom Endpoints Tests
  test "should get today's appointments" do
    get todays_appointments_url
    assert_response :success
    assert_not_nil assigns(:appointments)
  end

  test "should get upcoming appointments" do
    get upcoming_appointments_url
    assert_response :success
    assert_not_nil assigns(:appointments)
  end

  test "should get appointments by date" do
    get appointments_by_date_url, params: { date: Date.current }
    assert_response :success
    assert_not_nil assigns(:appointments)
  end

  test "should get appointment statistics" do
    get appointment_statistics_url
    assert_response :success
    assert_not_nil assigns(:stats)
  end

  test "should get doctor schedule" do
    get doctor_schedule_appointments_url, params: { 
      doctor_id: @doctor.id,
      date: Date.current
    }
    assert_response :success
    assert_not_nil assigns(:appointments)
  end

  test "should get patient appointments history" do
    get patient_appointment_history_url, params: { patient_id: @patient.id }
    assert_response :success
    assert_not_nil assigns(:appointments)
  end

  # Search and Filter Tests
  test "should search appointments by patient name" do
    get appointments_url, params: { search: @appointment.patient.first_name }
    assert_response :success
    assert_includes @response.body, @appointment.patient.full_name
  end

  test "should search appointments by doctor name" do
    get appointments_url, params: { search: @appointment.doctor.first_name }
    assert_response :success
    assert_includes @response.body, @appointment.doctor.full_name
  end

  test "should filter appointments by appointment type" do
    get appointments_url, params: { appointment_type: "consultation" }
    assert_response :success
  end

  test "should filter appointments by duration" do
    get appointments_url, params: { min_duration: 30, max_duration: 60 }
    assert_response :success
  end

  # API/JSON Response Tests
  test "should get index as JSON" do
    get appointments_url, as: :json
    assert_response :success
    
    json_response = JSON.parse(@response.body)
    assert json_response.is_a?(Array)
    assert json_response.any? { |a| a["id"] == @appointment.id }
  end

  test "should show appointment as JSON" do
    get appointment_url(@appointment), as: :json
    assert_response :success
    
    json_response = JSON.parse(@response.body)
    assert_equal @appointment.id, json_response["id"]
    assert_equal @appointment.status, json_response["status"]
    assert_equal @appointment.duration_minutes, json_response["duration_minutes"]
  end

  test "should create appointment via JSON" do
    assert_difference("Appointment.count") do
      post appointments_url, params: { appointment: @valid_attributes }, as: :json
    end

    assert_response :created
    json_response = JSON.parse(@response.body)
    assert_equal @valid_attributes[:doctor_id], json_response["doctor_id"]
  end

  test "should update appointment via JSON" do
    patch appointment_url(@appointment), params: { 
      appointment: { notes: "Updated via JSON" } 
    }, as: :json
    
    assert_response :success
    @appointment.reload
    assert_equal "Updated via JSON", @appointment.notes
  end

  test "should destroy appointment via JSON" do
    assert_difference("Appointment.count", -1) do
      delete appointment_url(@appointment), as: :json
    end

    assert_response :no_content
  end

  test "should confirm appointment via JSON" do
    patch confirm_appointment_url(@appointment), as: :json
    
    assert_response :success
    @appointment.reload
    assert_equal "confirmed", @appointment.status
  end

  # Calendar Integration Tests
  test "should get appointments for calendar view" do
    get appointments_calendar_url, params: { 
      start: Date.current.beginning_of_month,
      end: Date.current.end_of_month
    }
    assert_response :success
    
    json_response = JSON.parse(@response.body)
    assert json_response.is_a?(Array)
  end

  test "should get available time slots" do
    get available_slots_url, params: { 
      doctor_id: @doctor.id,
      date: Date.current
    }
    assert_response :success
    
    json_response = JSON.parse(@response.body)
    assert json_response.is_a?(Array)
  end

  # Notification Tests
  test "should send confirmation email when appointment is confirmed" do
    assert_emails 1 do
      patch confirm_appointment_url(@appointment)
    end
  end

  test "should send cancellation email when appointment is cancelled" do
    assert_emails 1 do
      patch cancel_appointment_url(@appointment)
    end
  end

  test "should send reminder email for upcoming appointments" do
    # This would test a background job or scheduled task
    # assert_emails 1 do
    #   AppointmentReminderJob.perform_now(@appointment)
    # end
  end

  # Business Logic Tests
  test "should calculate appointment end time correctly" do
    get appointment_url(@appointment)
    assert_response :success
    
    expected_end_time = @appointment.appointment_date + @appointment.duration_minutes.minutes
    assert_includes @response.body, expected_end_time.strftime("%I:%M %p")
  end

  test "should show appointment conflicts" do
    # Create a conflicting appointment
    conflicting_appointment = Appointment.create!(
      doctor: @appointment.doctor,
      patient: patients(:senior_patient),
      appointment_date: @appointment.appointment_date + 15.minutes,
      duration_minutes: 30,
      status: 'scheduled'
    )

    get appointment_conflicts_url(@appointment)
    assert_response :success
    assert_includes @response.body, conflicting_appointment.patient.full_name
  end

  # Error Handling Tests
  test "should handle invalid JSON requests gracefully" do
    post appointments_url, params: "invalid json", as: :json
    assert_response :bad_request
  end

  test "should require authentication for create actions" do
    # This test assumes authentication will be implemented
    # post appointments_url, params: { appointment: @valid_attributes }
    # assert_redirected_to login_url
  end

  test "should require proper privileges for destroy actions" do
    # This test assumes authorization will be implemented
    # delete appointment_url(@appointment)
    # assert_response :forbidden
  end

  # Data Integrity Tests
  test "should validate appointment date is not too far in future" do
    far_future_attributes = @valid_attributes.merge(
      appointment_date: 2.years.from_now
    )
    
    assert_no_difference("Appointment.count") do
      post appointments_url, params: { appointment: far_future_attributes }
    end

    assert_response :unprocessable_entity
    assert_select ".error", text: /cannot be more than 1 year in the future/
  end

  test "should validate reasonable duration" do
    long_duration_attributes = @valid_attributes.merge(duration_minutes: 500)
    
    assert_no_difference("Appointment.count") do
      post appointments_url, params: { appointment: long_duration_attributes }
    end

    assert_response :unprocessable_entity
    assert_select ".error", text: /must be between 15 and 240 minutes/
  end

  test "should prevent double booking patient" do
    # Create an existing appointment for the patient
    existing_appointment = Appointment.create!(
      doctor: doctors(:family_doctor),
      patient: @patient,
      appointment_date: @valid_attributes[:appointment_date],
      duration_minutes: 30,
      status: 'scheduled'
    )

    overlapping_attributes = @valid_attributes.merge(
      appointment_date: existing_appointment.appointment_date + 10.minutes
    )
    
    assert_no_difference("Appointment.count") do
      post appointments_url, params: { appointment: overlapping_attributes }
    end

    assert_response :unprocessable_entity
    assert_select ".error", text: /patient already has an appointment at this time/
  end
end
