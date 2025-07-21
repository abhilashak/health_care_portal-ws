class CreateHealthcareFacilities < ActiveRecord::Migration[8.0]
  def change
    create_table :healthcare_facilities do |t|
      # STI column
      t.string :type, null: false
      
      # Common fields
      t.string :name, null: false
      t.text :address, null: false
      t.string :phone, null: false
      t.string :email, null: false
      t.string :website
      t.string :registration_number, null: false
      t.boolean :active, default: true, null: false
      t.string :contact_person
      t.string :contact_person_phone
      t.string :contact_person_email
      t.string :emergency_contact
      t.string :emergency_phone
      t.jsonb :operating_hours, default: {}
      t.point :location
      t.string :timezone
      t.string :status, default: 'active', null: false
      t.text :description
      t.string :logo_url
      
      # Hospital specific fields
      t.text :specialties, array: true, default: []
      
      # Clinic specific fields
      t.string :facility_type
      t.integer :number_of_doctors
      t.boolean :accepts_insurance, default: false
      t.boolean :accepts_new_patients, default: true
      t.text :languages_spoken, array: true, default: []
      t.text :services, array: true, default: []

      t.timestamps null: false
    end

    # Add indexes
    add_index :healthcare_facilities, :name, unique: true, name: 'unique_healthcare_facility_names'
    add_index :healthcare_facilities, :email, unique: true, name: 'unique_healthcare_facility_emails'
    add_index :healthcare_facilities, :registration_number, unique: true
    add_index :healthcare_facilities, :phone, unique: true, name: 'index_healthcare_facilities_on_phone'
    add_index :healthcare_facilities, :active, where: 'active = true', name: 'index_healthcare_facilities_on_active_status'
    add_index :healthcare_facilities, :type, name: 'index_healthcare_facilities_on_type'
    
    # Add GIN indexes for array columns
    add_index :healthcare_facilities, :specialties, using: 'gin', name: 'index_healthcare_facilities_on_specialties'
    add_index :healthcare_facilities, :services, using: 'gin', name: 'index_healthcare_facilities_on_services'
    add_index :healthcare_facilities, :languages_spoken, using: 'gin', name: 'index_healthcare_facilities_on_languages_spoken'
    
    # Add GIN index for JSONB column
    add_index :healthcare_facilities, :operating_hours, using: :gin, name: 'index_healthcare_facilities_on_operating_hours'
    
    # Add index for facility type for faster filtering
    add_index :healthcare_facilities, :facility_type, name: 'index_healthcare_facilities_on_facility_type'
    
    # Add index for insurance acceptance
    add_index :healthcare_facilities, :accepts_insurance, where: 'accepts_insurance = true',
              name: 'index_healthcare_facilities_that_accept_insurance'
    
    # Add index for new patients acceptance
    add_index :healthcare_facilities, :accepts_new_patients, where: 'accepts_new_patients = true',
              name: 'index_healthcare_facilities_accepting_new_patients'
    
    # Add a check constraint for email format
    reversible do |dir|
      dir.up do
        execute <<-SQL
          ALTER TABLE healthcare_facilities
          ADD CONSTRAINT check_valid_healthcare_facility_email
          CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$');
        SQL
      end
      dir.down do
        execute 'ALTER TABLE healthcare_facilities DROP CONSTRAINT IF EXISTS check_valid_healthcare_facility_email;'
      end
    end
  end
end
