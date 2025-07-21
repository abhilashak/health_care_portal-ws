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
    t.string "type", null: false
    t.string "name", null: false
    t.text "address", null: false
    t.string "phone", null: false
    t.string "email", null: false
    t.string "website"
    t.string "registration_number", null: false
    t.boolean "active", default: true, null: false
    t.string "contact_person"
    t.string "contact_person_phone"
    t.string "contact_person_email"
    t.string "emergency_contact"
    t.string "emergency_phone"
    t.jsonb "operating_hours", default: {}
    t.point "location"
    t.string "timezone"
    t.string "status", default: "active", null: false
    t.text "description"
    t.string "logo_url"
    t.text "specialties", default: [], array: true
    t.string "facility_type"
    t.integer "number_of_doctors"
    t.boolean "accepts_insurance", default: false
    t.boolean "accepts_new_patients", default: true
    t.text "languages_spoken", default: [], array: true
    t.text "services", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["accepts_insurance"], name: "index_healthcare_facilities_that_accept_insurance", where: "(accepts_insurance = true)"
    t.index ["accepts_new_patients"], name: "index_healthcare_facilities_accepting_new_patients", where: "(accepts_new_patients = true)"
    t.index ["active"], name: "index_healthcare_facilities_on_active_status", where: "(active = true)"
    t.index ["email"], name: "unique_healthcare_facility_emails", unique: true
    t.index ["facility_type"], name: "index_healthcare_facilities_on_facility_type"
    t.index ["languages_spoken"], name: "index_healthcare_facilities_on_languages_spoken", using: :gin
    t.index ["name"], name: "unique_healthcare_facility_names", unique: true
    t.index ["operating_hours"], name: "index_healthcare_facilities_on_operating_hours", using: :gin
    t.index ["phone"], name: "index_healthcare_facilities_on_phone", unique: true
    t.index ["registration_number"], name: "index_healthcare_facilities_on_registration_number", unique: true
    t.index ["services"], name: "index_healthcare_facilities_on_services", using: :gin
    t.index ["specialties"], name: "index_healthcare_facilities_on_specialties", using: :gin
    t.index ["type"], name: "index_healthcare_facilities_on_type"
    t.check_constraint "email::text ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'::text", name: "check_valid_healthcare_facility_email"
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
