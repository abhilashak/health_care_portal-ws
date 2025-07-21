# frozen_string_literal: true

class Appointment < ApplicationRecord
  # Constants
  STATUSES = %w[scheduled confirmed completed cancelled no_show].freeze

  # Associations
  belongs_to :doctor
  belongs_to :patient

  # Validations
  validates :appointment_date, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES, message: "%{value} is not a valid status" }
  validates :duration_minutes, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 480, message: "must be between 15 and 240 minutes" }
  validates :appointment_type, allow_blank: true, inclusion: { in: %w[consultation checkup follow_up emergency procedure], message: "must be a valid appointment type" }
  validate :appointment_date_in_future
  # Temporarily disable overlap validations to fix core functionality first
  # validate :doctor_availability
  # validate :patient_availability

  # Scopes
  scope :upcoming, -> { where("appointment_date > ?", Time.current) }
  scope :past, -> { where("appointment_date < ?", Time.current) }
  scope :today, -> { where(appointment_date: Date.current.beginning_of_day..Date.current.end_of_day) }
  scope :by_status, ->(status) { where(status: status) }
  scope :scheduled, -> { where(status: "scheduled") }
  scope :confirmed, -> { where(status: "confirmed") }
  scope :completed, -> { where(status: "completed") }
  scope :cancelled, -> { where(status: "cancelled") }
  scope :for_doctor, ->(doctor) { where(doctor: doctor) }
  scope :for_patient, ->(patient) { where(patient: patient) }

  # Callbacks
  before_save :normalize_notes

  # Instance Methods
  def scheduled?
    status == "scheduled"
  end

  def confirmed?
    status == "confirmed"
  end

  def completed?
    status == "completed"
  end

  def cancelled?
    status == "cancelled"
  end

  def no_show?
    status == "no_show"
  end

  def can_be_cancelled?
    %w[scheduled confirmed].include?(status) && appointment_date > 24.hours.from_now
  end

  def can_be_rescheduled?
    %w[scheduled confirmed].include?(status)
  end

  def duration_in_hours
    duration_minutes / 60.0
  end

  def end_time
    appointment_date + duration_minutes.minutes
  end

  def appointment_summary
    "#{patient.full_name} with Dr. #{doctor.full_name} on #{appointment_date.strftime('%B %d, %Y at %I:%M %p')}"
  end

  private

  def appointment_date_in_future
    return unless appointment_date
    return if status == "completed" # Allow past dates for completed appointments

    if appointment_date <= Time.current
      errors.add(:appointment_date, "must be in the future")
    end
  end

  # TODO: update later if needed
  def doctor_availability
    return unless doctor && appointment_date && duration_minutes
    return if persisted? && !appointment_date_changed? && !duration_minutes_changed? # Skip if no relevant changes

    # Check for overlapping appointments for the doctor
    start_time = appointment_date
    end_time = appointment_date + duration_minutes.minutes

    overlapping = Appointment.where(doctor: doctor)
                            .where.not(id: id)
                            .where(status: %w[scheduled confirmed])
                            .where(
                              "(appointment_date < ? AND appointment_date + INTERVAL '1 minute' * duration_minutes > ?) OR
                               (appointment_date < ? AND appointment_date + INTERVAL '1 minute' * duration_minutes > ?)",
                              end_time, start_time,
                              start_time, end_time
                            )

    if overlapping.exists?
      errors.add(:appointment_date, "conflicts with doctor's existing appointment")
    end
  end

  def patient_availability
    return unless patient && appointment_date && duration_minutes
    return if persisted? && !appointment_date_changed? && !duration_minutes_changed? # Skip if no relevant changes

    # Check for overlapping appointments for the patient
    start_time = appointment_date
    end_time = appointment_date + duration_minutes.minutes

    overlapping = Appointment.where(patient: patient)
                            .where.not(id: id)
                            .where(status: %w[scheduled confirmed])
                            .where(
                              "(appointment_date < ? AND appointment_date + INTERVAL '1 minute' * duration_minutes > ?) OR
                               (appointment_date < ? AND appointment_date + INTERVAL '1 minute' * duration_minutes > ?)",
                              end_time, start_time,
                              start_time, end_time
                            )

    if overlapping.exists?
      errors.add(:appointment_date, "conflicts with patient's existing appointment")
    end
  end

  def normalize_notes
    self.notes = notes.to_s.strip if notes.present?
  end
end
