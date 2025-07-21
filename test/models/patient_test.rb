# frozen_string_literal: true

require_relative "application_model_test_case"

class PatientTest < ApplicationModelTestCase
  # Validation Tests
  test "should be valid with valid attributes" do
    patient = patients(:adult_patient)
    assert patient.valid?, "Patient should be valid with valid attributes"
  end

  test "should require first_name" do
    patient = patients(:adult_patient)
    patient.first_name = nil
    assert_not patient.valid?
    assert_includes patient.errors[:first_name], "can't be blank"
  end

  test "should require last_name" do
    patient = patients(:adult_patient)
    patient.last_name = nil
    assert_not patient.valid?
    assert_includes patient.errors[:last_name], "can't be blank"
  end

  test "should require date_of_birth" do
    patient = patients(:adult_patient)
    patient.date_of_birth = nil
    assert_not patient.valid?
    assert_includes patient.errors[:date_of_birth], "can't be blank"
  end

  test "should require email" do
    patient = patients(:adult_patient)
    patient.email = nil
    assert_not patient.valid?
    assert_includes patient.errors[:email], "can't be blank"
  end

  test "should require unique email" do
    existing_patient = patients(:adult_patient)
    new_patient = Patient.new(
      first_name: "Different",
      last_name: "Person",
      date_of_birth: 25.years.ago.to_date,
      email: existing_patient.email
    )
    assert_not new_patient.valid?
    assert_includes new_patient.errors[:email], "has already been taken"
  end

  test "should validate email format" do
    patient = patients(:adult_patient)
    invalid_emails = [ "invalid", "test@", "@domain.com", "test.domain.com" ]

    invalid_emails.each do |email|
      patient.email = email
      assert_not patient.valid?, "Email #{email} should be invalid"
      assert_includes patient.errors[:email], "must be a valid email address"
    end
  end

  # Scope Tests
  test "search_by_name scope should find patients by first or last name" do
    results = Patient.search_by_name("Alice")
    assert_includes results, patients(:adult_patient)

    results = Patient.search_by_name("Johnson")
    assert_includes results, patients(:adult_patient)

    results = Patient.search_by_name("xyz")
    assert_empty results
  end

  test "search_by_email scope should find patients by email" do
    results = Patient.search_by_email("alice.johnson")
    assert_includes results, patients(:adult_patient)

    results = Patient.search_by_email("nonexistent")
    assert_empty results
  end

  test "born_after scope should find patients born after given date" do
    cutoff_date = 20.years.ago.to_date
    results = Patient.born_after(cutoff_date)
    assert_includes results, patients(:minor_patient)
    assert_includes results, patients(:teen_patient)
    assert_not_includes results, patients(:adult_patient)
  end

  test "born_before scope should find patients born before given date" do
    cutoff_date = 20.years.ago.to_date
    results = Patient.born_before(cutoff_date)
    assert_includes results, patients(:adult_patient)
    assert_includes results, patients(:senior_patient)
    assert_not_includes results, patients(:minor_patient)
  end

  # Callback Tests
  test "should normalize names on validation" do
    patient = Patient.new(
      first_name: "  john  ",
      last_name: "  doe  ",
      date_of_birth: 30.years.ago.to_date,
      email: "john.doe@email.com"
    )
    patient.valid?
    assert_equal "John", patient.first_name
    assert_equal "Doe", patient.last_name
  end

  test "should normalize email on save" do
    patient = Patient.new(
      first_name: "Test",
      last_name: "User",
      date_of_birth: 30.years.ago.to_date,
      email: "TEST@EXAMPLE.COM"
    )
    patient.save!
    assert_equal "test@example.com", patient.email
  end

  # Instance Method Tests
  test "full_name should return first and last name" do
    patient = patients(:adult_patient)
    assert_equal "Alice Johnson", patient.full_name
  end

  test "age should calculate correct age" do
    patient = patients(:adult_patient)
    expected_age = (Date.current - patient.date_of_birth).to_i / 365
    assert_in_delta expected_age, patient.age, 1
  end

  test "age should return nil when date_of_birth is nil" do
    patient = Patient.new(
      first_name: "Test",
      last_name: "User",
      email: "test@example.com"
    )
    assert_nil patient.age
  end

  test "adult? should return true for patients 18 and older" do
    patient = patients(:adult_patient)
    assert patient.adult?
  end

  test "adult? should return false for patients under 18" do
    patient = patients(:minor_patient)
    assert_not patient.adult?
  end

  test "adult? should return true for patients exactly 18" do
    patient = Patient.new(
      first_name: "Test",
      last_name: "Adult",
      date_of_birth: 18.years.ago.to_date,
      email: "test.adult@email.com"
    )
    assert patient.adult?
  end

  test "minor? should return true for patients under 18" do
    patient = patients(:minor_patient)
    assert patient.minor?
  end

  test "minor? should return false for patients 18 and older" do
    patient = patients(:adult_patient)
    assert_not patient.minor?
  end

  test "senior? should return true for patients 65 and older" do
    patient = patients(:senior_patient)
    assert patient.senior?
  end

  test "senior? should return false for patients under 65" do
    patient = patients(:adult_patient)
    assert_not patient.senior?
  end

  test "senior? should return true for patients exactly 65" do
    patient = Patient.new(
      first_name: "Test",
      last_name: "Senior",
      date_of_birth: 65.years.ago.to_date,
      email: "test.senior@email.com"
    )
    assert patient.senior?
  end

  # Age category tests with fixtures
  test "should correctly categorize adult patient" do
    patient = patients(:adult_patient)
    assert patient.adult?
    assert_not patient.minor?
    assert_not patient.senior?
  end

  test "should correctly categorize senior patient" do
    patient = patients(:senior_patient)
    assert patient.adult?
    assert_not patient.minor?
    assert patient.senior?
  end

  test "should correctly categorize minor patient" do
    patient = patients(:minor_patient)
    assert_not patient.adult?
    assert patient.minor?
    assert_not patient.senior?
  end

  test "should correctly categorize teen patient" do
    patient = patients(:teen_patient)
    assert_not patient.adult?
    assert patient.minor?
    assert_not patient.senior?
  end

  # Database Constraint Tests
  test "should enforce email format constraint at database level" do
    # This tests the database check constraint
    assert_raises(ActiveRecord::StatementInvalid) do
      Patient.connection.execute(
        "INSERT INTO patients (first_name, last_name, date_of_birth, email, created_at, updated_at)
         VALUES ('Test', 'User', '1990-01-01', 'invalid-email', NOW(), NOW())"
      )
    end
  end

  test "should enforce birth date not in future constraint" do
    # This tests the database check constraint
    assert_raises(ActiveRecord::StatementInvalid) do
      Patient.connection.execute(
        "INSERT INTO patients (first_name, last_name, date_of_birth, email, created_at, updated_at)
         VALUES ('Test', 'User', '#{1.year.from_now.to_date}', 'test@example.com', NOW(), NOW())"
      )
    end
  end

  test "should enforce reasonable age constraint" do
    # This tests the database check constraint for maximum age
    assert_raises(ActiveRecord::StatementInvalid) do
      Patient.connection.execute(
        "INSERT INTO patients (first_name, last_name, date_of_birth, email, created_at, updated_at)
         VALUES ('Test', 'User', '#{200.years.ago.to_date}', 'test@example.com', NOW(), NOW())"
      )
    end
  end

  # Edge Cases
  test "should handle leap year birth dates correctly" do
    leap_year_patient = Patient.create!(
      first_name: "Leap",
      last_name: "Year",
      date_of_birth: Date.new(2000, 2, 29),
      email: "leap@example.com"
    )

    assert leap_year_patient.valid?
    assert leap_year_patient.age > 0
  end

  test "should handle patients born today" do
    today_patient = Patient.create!(
      first_name: "Born",
      last_name: "Today",
      date_of_birth: Date.current,
      email: "today@example.com"
    )

    assert today_patient.valid?
    assert_equal 0, today_patient.age
    assert today_patient.minor?
  end
end
