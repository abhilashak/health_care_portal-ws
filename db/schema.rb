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

ActiveRecord::Schema[8.0].define(version: 2025_07_21_100953) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "doctors", force: :cascade do |t|
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "specialization", null: false
    t.bigint "hospital_id"
    t.bigint "clinic_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["clinic_id"], name: "index_doctors_on_clinic_id"
    t.index ["first_name", "last_name"], name: "index_doctors_on_full_name"
    t.index ["hospital_id"], name: "index_doctors_on_hospital_id"
    t.index ["specialization"], name: "index_doctors_on_specialization"
    t.check_constraint "hospital_id IS NOT NULL OR clinic_id IS NOT NULL", name: "doctors_must_belong_to_facility"
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
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.date "date_of_birth", null: false
    t.string "email", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date_of_birth"], name: "index_patients_on_date_of_birth"
    t.index ["email"], name: "unique_patient_emails", unique: true
    t.index ["first_name", "last_name"], name: "index_patients_on_full_name"
    t.check_constraint "date_of_birth <= CURRENT_DATE", name: "patients_birth_date_not_future"
    t.check_constraint "date_of_birth >= (CURRENT_DATE - 'P150Y'::interval)", name: "patients_reasonable_age"
    t.check_constraint "email::text ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+.[A-Za-z]{2,}$'::text", name: "patients_email_format_check"
  end

  add_foreign_key "doctors", "healthcare_facilities", column: "clinic_id", on_delete: :nullify
  add_foreign_key "doctors", "healthcare_facilities", column: "hospital_id", on_delete: :nullify
end
