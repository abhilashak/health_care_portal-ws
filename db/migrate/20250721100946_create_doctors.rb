class CreateDoctors < ActiveRecord::Migration[8.0]
  def change
    create_table :doctors do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :specialization, null: false
      t.bigint :hospital_id, null: true
      t.bigint :clinic_id, null: true

      t.timestamps null: false
    end

    # Add indexes
    add_index :doctors, :hospital_id
    add_index :doctors, :clinic_id
    add_index :doctors, :specialization
    add_index :doctors, [ :first_name, :last_name ], name: 'index_doctors_on_full_name'

    # Add foreign key constraints
    add_foreign_key :doctors, :healthcare_facilities, column: :hospital_id, on_delete: :nullify
    add_foreign_key :doctors, :healthcare_facilities, column: :clinic_id, on_delete: :nullify

    # Add check constraint to ensure doctor belongs to at least one facility
    add_check_constraint :doctors, 'hospital_id IS NOT NULL OR clinic_id IS NOT NULL', name: 'doctors_must_belong_to_facility'
  end
end
