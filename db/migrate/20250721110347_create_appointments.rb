class CreateAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :appointments do |t|
      t.references :doctor, null: false, foreign_key: true
      t.references :patient, null: false, foreign_key: true
      t.datetime :appointment_date, null: false
      t.string :status, null: false, default: 'scheduled'
      t.text :notes
      t.integer :duration_minutes, default: 30

      t.timestamps
    end

    # Add indexes for performance
    add_index :appointments, :appointment_date
    add_index :appointments, :status
    add_index :appointments, [ :doctor_id, :appointment_date ], name: 'index_appointments_on_doctor_and_date'
    add_index :appointments, [ :patient_id, :appointment_date ], name: 'index_appointments_on_patient_and_date'

    # Add check constraints
    add_check_constraint :appointments, "status IN ('scheduled', 'confirmed', 'completed', 'cancelled', 'no_show')", name: 'appointments_status_check'
    add_check_constraint :appointments, "appointment_date >= CURRENT_TIMESTAMP", name: 'appointments_future_date_check'
    add_check_constraint :appointments, "duration_minutes > 0 AND duration_minutes <= 480", name: 'appointments_duration_check'
  end
end
