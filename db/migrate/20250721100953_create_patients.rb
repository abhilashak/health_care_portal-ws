class CreatePatients < ActiveRecord::Migration[8.0]
  def change
    create_table :patients do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.date :date_of_birth, null: false
      t.string :email, null: false

      t.timestamps null: false
    end

    # Add indexes
    add_index :patients, :email, unique: true, name: 'unique_patient_emails'
    add_index :patients, [ :first_name, :last_name ], name: 'index_patients_on_full_name'
    add_index :patients, :date_of_birth

    # Add check constraint for email format
    add_check_constraint :patients, "email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'", name: 'patients_email_format_check'

    # Add check constraint for reasonable birth date (not in future, not too old)
    add_check_constraint :patients, 'date_of_birth <= CURRENT_DATE', name: 'patients_birth_date_not_future'
    add_check_constraint :patients, 'date_of_birth >= CURRENT_DATE - INTERVAL \'150 years\'', name: 'patients_reasonable_age'
  end
end
