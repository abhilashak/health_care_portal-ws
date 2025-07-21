class FixAppointmentDateConstraint < ActiveRecord::Migration[8.0]
  def change
    # Remove the overly restrictive future date constraint
    remove_check_constraint :appointments, name: 'appointments_future_date_check'

    # Add a more reasonable constraint that allows appointments from the past 2 years
    # This allows for completed appointments while preventing very old dates
    add_check_constraint :appointments,
      "appointment_date >= CURRENT_TIMESTAMP - INTERVAL '2 years'",
      name: 'appointments_reasonable_date_check'
  end
end
