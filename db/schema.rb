# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_07_21_102153) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "appointments", force: :cascade do |t|
    t.bigint "doctor_id", null: false
    t.bigint "patient_id", null: false
    t.datetime "scheduled_at", null: false
    t.string "status", limit: 50, default: "pending", null: false
    t.text "notes"
    t.integer "duration_minutes", default: 30, null: false
    t.string "appointment_type", limit: 100, default: "routine", null: false
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appointment_type", "scheduled_at"], name: "index_appointments_type_schedule"
    t.index ["doctor_id", "patient_id", "scheduled_at"], name: "index_appointments_doctor_patient_schedule"
    t.index ["doctor_id", "scheduled_at"], name: "index_appointments_doctor_schedule"
    t.index ["doctor_id", "status"], name: "index_appointments_doctor_status"
    t.index ["doctor_id"], name: "index_appointments_doctor_id"
    t.index ["patient_id", "scheduled_at"], name: "index_appointments_patient_schedule"
    t.index ["patient_id", "status"], name: "index_appointments_patient_status"
    t.index ["patient_id"], name: "index_appointments_patient_id"
    t.index ["scheduled_at", "status"], name: "index_appointments_schedule_status"
    t.index ["scheduled_at"], name: "index_appointments_scheduled_at"
    t.index ["status"], name: "index_appointments_status"
    t.check_constraint "appointment_type::text = ANY (ARRAY['routine'::character varying::text, 'follow_up'::character varying::text, 'emergency'::character varying::text, 'consultation'::character varying::text, 'procedure'::character varying::text, 'surgery'::character varying::text, 'therapy'::character varying::text, 'screening'::character varying::text, 'vaccination'::character varying::text, 'other'::character varying::text])", name: "check_appointments_valid_type"
    t.check_constraint "confirmed_at IS NULL OR confirmed_at <= scheduled_at", name: "check_appointments_confirmed_before_scheduled"
    t.check_constraint "duration_minutes >= 5 AND duration_minutes <= 480", name: "check_appointments_reasonable_duration"
    t.check_constraint "duration_minutes IS NOT NULL", name: "check_appointments_duration_not_null"
    t.check_constraint "scheduled_at <= (CURRENT_TIMESTAMP + 'P2Y'::interval)", name: "check_appointments_reasonable_future"
    t.check_constraint "scheduled_at >= (CURRENT_TIMESTAMP - 'PT1H'::interval)", name: "check_appointments_not_too_far_past"
    t.check_constraint "status::text <> 'confirmed'::text OR confirmed_at IS NOT NULL", name: "check_appointments_confirmed_status_has_timestamp"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying::text, 'confirmed'::character varying::text, 'in_progress'::character varying::text, 'completed'::character varying::text, 'cancelled'::character varying::text, 'no_show'::character varying::text, 'rescheduled'::character varying::text])", name: "check_appointments_valid_status"
  end

  create_table "doctors", force: :cascade do |t|
    t.string "first_name", limit: 100, null: false
    t.string "last_name", limit: 100, null: false
    t.string "email", limit: 255, null: false
    t.string "phone", limit: 20, null: false
    t.string "specialization", limit: 150, null: false
    t.string "license_number", limit: 50, null: false
    t.integer "years_of_experience", default: 0, null: false
    t.bigint "hospital_id"
    t.bigint "clinic_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["clinic_id", "specialization"], name: "idx_doctors_clinic_specialization"
    t.index ["clinic_id"], name: "idx_doctors_clinic_id"
    t.index ["email"], name: "idx_doctors_unique_email", unique: true
    t.index ["hospital_id", "specialization"], name: "idx_doctors_hospital_specialization"
    t.index ["hospital_id"], name: "idx_doctors_hospital_id"
    t.index ["last_name", "first_name"], name: "idx_doctors_name"
    t.index ["license_number"], name: "idx_doctors_unique_license", unique: true
    t.index ["specialization"], name: "idx_doctors_specialization"
    t.index ["years_of_experience"], name: "idx_doctors_experience"
    t.check_constraint "email::text ~~ '%@%'::text", name: "check_doctors_email_format"
    t.check_constraint "hospital_id IS NULL OR clinic_id IS NULL OR hospital_id <> clinic_id", name: "check_doctors_different_facilities"
    t.check_constraint "length(first_name::text) >= 2", name: "check_doctors_first_name_length"
    t.check_constraint "length(last_name::text) >= 2", name: "check_doctors_last_name_length"
    t.check_constraint "length(license_number::text) >= 3", name: "check_doctors_license_length"
    t.check_constraint "length(phone::text) >= 10", name: "check_doctors_phone_length"
    t.check_constraint "length(specialization::text) >= 3", name: "check_doctors_specialization_length"
    t.check_constraint "years_of_experience >= 0 AND years_of_experience <= 70", name: "check_doctors_experience_range"
  end

  create_table "healthcare_facilities", force: :cascade do |t|
    t.string "type", limit: 50, null: false
    t.string "name", limit: 255, null: false
    t.text "address", null: false
    t.string "phone", limit: 20, null: false
    t.string "email", limit: 255, null: false
    t.string "city", limit: 100, null: false
    t.string "state", limit: 50, null: false
    t.string "zip_code", limit: 10, null: false
    t.date "established_date", null: false
    t.string "website_url", limit: 500
    t.string "health_care_type", limit: 100, null: false
    t.integer "bed_capacity"
    t.boolean "emergency_services"
    t.text "services_offered"
    t.boolean "accepts_walk_ins"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_healthcare_facilities_unique_email", unique: true
    t.index ["established_date"], name: "index_healthcare_facilities_established"
    t.index ["health_care_type"], name: "index_healthcare_facilities_healthcare_type"
    t.index ["name"], name: "index_healthcare_facilities_unique_name", unique: true
    t.index ["type", "accepts_walk_ins"], name: "index_clinics_walk_ins", where: "((type)::text = 'Clinic'::text)"
    t.index ["type", "bed_capacity"], name: "index_hospitals_bed_capacity", where: "((type)::text = 'Hospital'::text)"
    t.index ["type", "city", "state"], name: "index_healthcare_facilities_type_location"
    t.index ["type", "emergency_services"], name: "index_hospitals_emergency", where: "((type)::text = 'Hospital'::text)"
    t.index ["type", "health_care_type"], name: "index_healthcare_facilities_type_healthcare_type"
    t.index ["type"], name: "index_healthcare_facilities_type"
    t.index ["zip_code"], name: "index_healthcare_facilities_zip_code"
    t.check_constraint "email::text ~~ '%@%'::text", name: "check_facility_email_format"
    t.check_constraint "length(name::text) >= 2", name: "check_facility_name_length"
    t.check_constraint "length(phone::text) >= 10", name: "check_facility_phone_length"
    t.check_constraint "type::text <> 'Clinic'::text OR (health_care_type::text = ANY (ARRAY['Family Practice'::character varying::text, 'Urgent Care'::character varying::text, 'Specialty'::character varying::text, 'Pediatric'::character varying::text, 'Internal Medicine'::character varying::text, 'Cardiology'::character varying::text, 'Dermatology'::character varying::text, 'Orthopedic'::character varying::text, 'Mental Health'::character varying::text, 'Dental'::character varying::text, 'Eye Care'::character varying::text, 'Other'::character varying::text]))", name: "check_clinic_valid_healthcare_type"
    t.check_constraint "type::text <> 'Clinic'::text OR length(services_offered) >= 5", name: "check_clinic_services_length"
    t.check_constraint "type::text <> 'Clinic'::text OR services_offered IS NOT NULL AND accepts_walk_ins IS NOT NULL", name: "check_clinic_required_fields"
    t.check_constraint "type::text <> 'Hospital'::text OR (health_care_type::text = ANY (ARRAY['General'::character varying::text, 'Specialty'::character varying::text, 'Teaching'::character varying::text, 'Psychiatric'::character varying::text, 'Rehabilitation'::character varying::text, 'Children'::character varying::text, 'Cancer'::character varying::text, 'Heart'::character varying::text, 'Other'::character varying::text]))", name: "check_hospital_valid_healthcare_type"
    t.check_constraint "type::text <> 'Hospital'::text OR bed_capacity >= 0", name: "check_hospital_bed_capacity_positive"
    t.check_constraint "type::text <> 'Hospital'::text OR bed_capacity IS NOT NULL AND emergency_services IS NOT NULL", name: "check_hospital_required_fields"
    t.check_constraint "type::text = ANY (ARRAY['Hospital'::character varying::text, 'Clinic'::character varying::text])", name: "check_valid_facility_type"
  end

  create_table "patients", force: :cascade do |t|
    t.string "first_name", limit: 100, null: false
    t.string "last_name", limit: 100, null: false
    t.string "email", limit: 255, null: false
    t.string "phone", limit: 20, null: false
    t.date "date_of_birth", null: false
    t.string "gender", limit: 20, null: false
    t.string "emergency_contact_name", limit: 150, null: false
    t.string "emergency_contact_phone", limit: 20, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date_of_birth"], name: "idx_patients_birth_date"
    t.index ["email"], name: "idx_patients_unique_email", unique: true
    t.index ["gender", "date_of_birth"], name: "idx_patients_demographics"
    t.index ["gender"], name: "idx_patients_gender"
    t.index ["last_name", "first_name", "date_of_birth"], name: "idx_patients_identification"
    t.index ["last_name", "first_name"], name: "idx_patients_name"
    t.index ["phone"], name: "idx_patients_phone"
    t.check_constraint "date_of_birth <= CURRENT_DATE", name: "check_patients_birth_date_past"
    t.check_constraint "date_of_birth >= '1900-01-01'::date", name: "check_patients_birth_date_reasonable"
    t.check_constraint "date_of_birth >= (CURRENT_DATE - 'P150Y'::interval)", name: "check_patients_maximum_age"
    t.check_constraint "email::text ~~ '%@%'::text", name: "check_patients_email_format"
    t.check_constraint "gender::text = ANY (ARRAY['male'::character varying::text, 'female'::character varying::text, 'other'::character varying::text, 'prefer_not_to_say'::character varying::text])", name: "check_patients_valid_gender"
    t.check_constraint "length(emergency_contact_name::text) >= 2", name: "check_patients_emergency_name_length"
    t.check_constraint "length(emergency_contact_phone::text) >= 10", name: "check_patients_emergency_phone_length"
    t.check_constraint "length(first_name::text) >= 2", name: "check_patients_first_name_length"
    t.check_constraint "length(last_name::text) >= 2", name: "check_patients_last_name_length"
    t.check_constraint "length(phone::text) >= 10", name: "check_patients_phone_length"
  end

  add_foreign_key "appointments", "doctors", on_delete: :cascade
  add_foreign_key "appointments", "patients", on_delete: :cascade
  add_foreign_key "doctors", "healthcare_facilities", column: "clinic_id", on_delete: :nullify
  add_foreign_key "doctors", "healthcare_facilities", column: "hospital_id", on_delete: :nullify
end
