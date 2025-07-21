# frozen_string_literal: true

require_relative "application_model_test_case"

class AppointmentTest < ApplicationModelTestCase
  def setup
    @hospital = healthcare_facilities(:general_hospital)
    @doctor = doctors(:cardiologist)
    @patient = patients(:adult_patient)
    @valid_attributes = {
      doctor: @doctor,
      patient: @patient,
      appointment_date: 2.days.from_now.beginning_of_hour,
      status: "scheduled",
      duration_minutes: 30,
      notes: "Regular checkup"
    }
  end

  # Validation Tests
  test "should be valid with valid attributes" do
    appointment = Appointment.new(@valid_attributes)
    assert appointment.valid?, "Appointment should be valid with valid attributes"
  end

  test "should require doctor" do
    appointment = Appointment.new(@valid_attributes.except(:doctor))
    assert_not appointment.valid?
    assert_includes appointment.errors[:doctor], "must exist"
  end

  test "should require patient" do
    appointment = Appointment.new(@valid_attributes.except(:patient))
    assert_not appointment.valid?
    assert_includes appointment.errors[:patient], "must exist"
  end

  test "should require appointment_date" do
    appointment = Appointment.new(@valid_attributes.except(:appointment_date))
    assert_not appointment.valid?
    assert_includes appointment.errors[:appointment_date], "can't be blank"
  end

  test "should require status" do
    appointment = Appointment.new(@valid_attributes.merge(status: nil))
    assert_not appointment.valid?
    assert_includes appointment.errors[:status], "can't be blank"
  end

  test "should validate status inclusion" do
    valid_statuses = %w[scheduled confirmed completed cancelled no_show]
    valid_statuses.each do |status|
      appointment = Appointment.new(@valid_attributes.merge(status: status))
      assert appointment.valid?, "Status #{status} should be valid"
    end

    appointment = Appointment.new(@valid_attributes.merge(status: "invalid_status"))
    assert_not appointment.valid?
    assert_includes appointment.errors[:status], "invalid_status is not a valid status"
  end

  test "should require duration_minutes" do
    appointment = Appointment.new(@valid_attributes.merge(duration_minutes: nil))
    assert_not appointment.valid?
    assert_includes appointment.errors[:duration_minutes], "can't be blank"
  end

  test "should validate duration_minutes numericality" do
    appointment = Appointment.new(@valid_attributes.merge(duration_minutes: 0))
    assert_not appointment.valid?
    assert_includes appointment.errors[:duration_minutes], "must be greater than 0"

    appointment = Appointment.new(@valid_attributes.merge(duration_minutes: 500))
    assert_not appointment.valid?
    assert_includes appointment.errors[:duration_minutes], "must be less than or equal to 480"

    appointment = Appointment.new(@valid_attributes.merge(duration_minutes: 30))
    assert appointment.valid?
  end

  test "should validate appointment_date is in future" do
    appointment = Appointment.new(@valid_attributes.merge(appointment_date: 1.hour.ago))
    assert_not appointment.valid?
    assert_includes appointment.errors[:appointment_date], "must be in the future"
  end

  # Association Tests
  test "should belong to doctor" do
    appointment = appointments(:scheduled_appointment)
    assert_equal doctors(:cardiologist), appointment.doctor
  end

  test "should belong to patient" do
    appointment = appointments(:scheduled_appointment)
    assert_equal patients(:adult_patient), appointment.patient
  end

  # Scope Tests
  test "upcoming scope should return future appointments" do
    upcoming = Appointment.upcoming
    upcoming.each do |appointment|
      assert appointment.appointment_date > Time.current
    end
  end

  test "past scope should return past appointments" do
    past = Appointment.past
    past.each do |appointment|
      assert appointment.appointment_date < Time.current
    end
  end

  test "by_status scope should filter by status" do
    scheduled = Appointment.by_status("scheduled")
    scheduled.each do |appointment|
      assert_equal "scheduled", appointment.status
    end
  end

  test "scheduled scope should return only scheduled appointments" do
    scheduled = Appointment.scheduled
    scheduled.each do |appointment|
      assert_equal "scheduled", appointment.status
    end
  end

  test "for_doctor scope should return appointments for specific doctor" do
    doctor_appointments = Appointment.for_doctor(@doctor)
    doctor_appointments.each do |appointment|
      assert_equal @doctor, appointment.doctor
    end
  end

  test "for_patient scope should return appointments for specific patient" do
    patient_appointments = Appointment.for_patient(@patient)
    patient_appointments.each do |appointment|
      assert_equal @patient, appointment.patient
    end
  end

  # Instance Method Tests
  test "status query methods should work correctly" do
    appointment = appointments(:scheduled_appointment)
    assert appointment.scheduled?
    assert_not appointment.confirmed?
    assert_not appointment.completed?
    assert_not appointment.cancelled?
    assert_not appointment.no_show?

    appointment.update!(status: "confirmed")
    assert_not appointment.scheduled?
    assert appointment.confirmed?
  end

  test "can_be_cancelled? should return correct value" do
    # Scheduled appointment in future (more than 24 hours)
    appointment = Appointment.new(@valid_attributes.merge(
      appointment_date: 2.days.from_now,
      status: "scheduled"
    ))
    appointment.save!
    assert appointment.can_be_cancelled?

    # Scheduled appointment too soon (less than 24 hours)
    appointment.update!(appointment_date: 12.hours.from_now)
    assert_not appointment.can_be_cancelled?

    # Completed appointment
    appointment.update!(status: "completed")
    assert_not appointment.can_be_cancelled?
  end

  test "can_be_rescheduled? should return correct value" do
    appointment = appointments(:scheduled_appointment)
    assert appointment.can_be_rescheduled?

    appointment.update!(status: "completed")
    assert_not appointment.can_be_rescheduled?
  end

  test "duration_in_hours should calculate correctly" do
    appointment = Appointment.new(@valid_attributes.merge(duration_minutes: 90))
    assert_equal 1.5, appointment.duration_in_hours
  end

  test "end_time should calculate correctly" do
    appointment = Appointment.new(@valid_attributes)
    expected_end = appointment.appointment_date + 30.minutes
    assert_equal expected_end, appointment.end_time
  end

  test "appointment_summary should format correctly" do
    appointment = appointments(:scheduled_appointment)
    summary = appointment.appointment_summary
    assert_includes summary, appointment.patient.full_name
    assert_includes summary, "Dr. #{appointment.doctor.full_name}"
    assert_includes summary, appointment.appointment_date.strftime("%B %d, %Y")
  end

  # Callback Tests
  test "should normalize notes on save" do
    appointment = Appointment.new(@valid_attributes.merge(notes: "  Test notes  "))
    appointment.save!
    assert_equal "Test notes", appointment.notes
  end

  # Database Constraint Tests
  test "should enforce database status constraint" do
    appointment = Appointment.new(@valid_attributes)
    appointment.save!

    assert_raises(ActiveRecord::StatementInvalid) do
      appointment.update_column(:status, "invalid_status")
    end
  end
end
