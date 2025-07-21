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

ActiveRecord::Schema[8.0].define(version: 2025_07_21_100013) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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
    t.check_constraint "type::text <> 'Clinic'::text OR (health_care_type::text = ANY (ARRAY['Family Practice'::character varying, 'Urgent Care'::character varying, 'Specialty'::character varying, 'Pediatric'::character varying, 'Internal Medicine'::character varying, 'Cardiology'::character varying, 'Dermatology'::character varying, 'Orthopedic'::character varying, 'Mental Health'::character varying, 'Dental'::character varying, 'Eye Care'::character varying, 'Other'::character varying]::text[]))", name: "check_clinic_valid_healthcare_type"
    t.check_constraint "type::text <> 'Clinic'::text OR length(services_offered) >= 5", name: "check_clinic_services_length"
    t.check_constraint "type::text <> 'Clinic'::text OR services_offered IS NOT NULL AND accepts_walk_ins IS NOT NULL", name: "check_clinic_required_fields"
    t.check_constraint "type::text <> 'Hospital'::text OR (health_care_type::text = ANY (ARRAY['General'::character varying, 'Specialty'::character varying, 'Teaching'::character varying, 'Psychiatric'::character varying, 'Rehabilitation'::character varying, 'Children'::character varying, 'Cancer'::character varying, 'Heart'::character varying, 'Other'::character varying]::text[]))", name: "check_hospital_valid_healthcare_type"
    t.check_constraint "type::text <> 'Hospital'::text OR bed_capacity >= 0", name: "check_hospital_bed_capacity_positive"
    t.check_constraint "type::text <> 'Hospital'::text OR bed_capacity IS NOT NULL AND emergency_services IS NOT NULL", name: "check_hospital_required_fields"
    t.check_constraint "type::text = ANY (ARRAY['Hospital'::character varying, 'Clinic'::character varying]::text[])", name: "check_valid_facility_type"
  end
end
