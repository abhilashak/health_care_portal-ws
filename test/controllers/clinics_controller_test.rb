# frozen_string_literal: true

require "test_helper"

class ClinicsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @clinic = healthcare_facilities(:family_clinic)
    @valid_attributes = {
      name: "New Family Clinic",
      address: "456 Community Health Blvd\nWellness Town, WT 54321",
      phone: "+1-555-987-6543",
      email: "contact@newfamily.com",
      registration_number: "CLINIC123456",
      facility_type: "primary_care",
      operating_hours: { 
        "monday" => "9:00-17:00", 
        "tuesday" => "9:00-17:00",
        "walk_in" => "9:00-12:00"
      },
      status: "active",
      services: ["General Checkup", "Vaccinations", "Lab Testing"],
      languages_spoken: ["English", "Spanish"],
      number_of_doctors: 3
    }
    @invalid_attributes = {
      name: "",
      address: "",
      phone: "invalid-phone",
      email: "invalid-email",
      registration_number: "",
      facility_type: "invalid_type",
      number_of_doctors: -1
    }
  end

  # Index Tests
  test "should get index" do
    get clinics_url
    assert_response :success
    assert_not_nil assigns(:clinics)
    assert_includes @response.body, @clinic.name
  end

  test "should get index with search parameter" do
    get clinics_url, params: { search: @clinic.name }
    assert_response :success
    assert_includes @response.body, @clinic.name
  end

  test "should get index filtered by clinic type" do
    get clinics_url, params: { clinic_type: @clinic.facility_type }
    assert_response :success
  end

  test "should get index filtered by services" do
    get clinics_url, params: { service: "General Checkup" }
    assert_response :success
  end

  test "should get index filtered by languages" do
    get clinics_url, params: { language: "English" }
    assert_response :success
  end

  # Show Tests
  test "should show clinic" do
    get clinic_url(@clinic)
    assert_response :success
    assert_includes @response.body, @clinic.name
    assert_includes @response.body, @clinic.address
  end

  test "should show clinic with doctors and services" do
    get clinic_url(@clinic)
    assert_response :success
    # Should display associated doctors
    @clinic.doctors.each do |doctor|
      assert_includes @response.body, doctor.full_name
    end
  end

  test "should return 404 for non-existent clinic" do
    assert_raises(ActiveRecord::RecordNotFound) do
      get clinic_url(id: 99999)
    end
  end

  # New Tests
  test "should get new" do
    get new_clinic_url
    assert_response :success
    assert_select "form[action=?]", clinics_path
  end

  # Create Tests
  test "should create clinic with valid attributes" do
    assert_difference("Clinic.count") do
      post clinics_url, params: { clinic: @valid_attributes }
    end

    clinic = Clinic.last
    assert_redirected_to clinic_url(clinic)
    assert_equal @valid_attributes[:name], clinic.name
    assert_equal @valid_attributes[:facility_type], clinic.facility_type
    assert_equal @valid_attributes[:number_of_doctors], clinic.number_of_doctors
  end

  test "should not create clinic with invalid attributes" do
    assert_no_difference("Clinic.count") do
      post clinics_url, params: { clinic: @invalid_attributes }
    end

    assert_response :unprocessable_entity
    assert_select ".error", text: /can't be blank/
  end

  test "should not create clinic with duplicate name" do
    duplicate_attributes = @valid_attributes.merge(name: @clinic.name)
    
    assert_no_difference("Clinic.count") do
      post clinics_url, params: { clinic: duplicate_attributes }
    end

    assert_response :unprocessable_entity
    assert_select ".error", text: /has already been taken/
  end

  # Edit Tests
  test "should get edit" do
    get edit_clinic_url(@clinic)
    assert_response :success
    assert_select "form[action=?]", clinic_path(@clinic)
    assert_select "input[value=?]", @clinic.name
  end

  # Update Tests
  test "should update clinic with valid attributes" do
    new_name = "Updated Clinic Name"
    patch clinic_url(@clinic), params: { 
      clinic: { 
        name: new_name, 
        facility_type: "urgent_care",
        number_of_doctors: 5
      } 
    }
    
    assert_redirected_to clinic_url(@clinic)
    @clinic.reload
    assert_equal new_name, @clinic.name
    assert_equal "urgent_care", @clinic.facility_type
    assert_equal 5, @clinic.number_of_doctors
  end

  test "should not update clinic with invalid attributes" do
    original_name = @clinic.name
    patch clinic_url(@clinic), params: { 
      clinic: { 
        name: "", 
        email: "invalid-email",
        number_of_doctors: -5
      } 
    }
    
    assert_response :unprocessable_entity
    @clinic.reload
    assert_equal original_name, @clinic.name
  end

  # Destroy Tests
  test "should destroy clinic" do
    assert_difference("Clinic.count", -1) do
      delete clinic_url(@clinic)
    end

    assert_redirected_to clinics_url
  end

  test "should not destroy clinic with associated doctors" do
    # Create a doctor associated with the clinic
    doctor = doctors(:family_doctor)
    doctor.update!(clinic: @clinic)
    
    assert_no_difference("Clinic.count") do
      delete clinic_url(@clinic)
    end

    assert_redirected_to clinic_url(@clinic)
    assert_match /cannot be deleted.*associated doctors/, flash[:alert]
  end

  # Custom Endpoints Tests
  test "should get clinic doctors" do
    get clinic_doctors_url(@clinic)
    assert_response :success
    assert_not_nil assigns(:doctors)
  end

  test "should get clinic services" do
    get clinic_services_url(@clinic)
    assert_response :success
    assert_not_nil assigns(:services)
  end

  test "should get clinic walk_in_hours" do
    get clinic_walk_in_hours_url(@clinic)
    assert_response :success
  end

  test "should get clinic appointment_hours" do
    get clinic_appointment_hours_url(@clinic)
    assert_response :success
  end

  test "should add service to clinic" do
    new_service = "Physical Therapy"
    post clinic_add_service_url(@clinic), params: { service: new_service }
    
    assert_redirected_to clinic_url(@clinic)
    @clinic.reload
    assert_includes @clinic.services, new_service
  end

  test "should remove service from clinic" do
    service_to_remove = @clinic.services.first
    delete clinic_remove_service_url(@clinic), params: { service: service_to_remove }
    
    assert_redirected_to clinic_url(@clinic)
    @clinic.reload
    assert_not_includes @clinic.services, service_to_remove
  end

  test "should add language to clinic" do
    new_language = "French"
    post clinic_add_language_url(@clinic), params: { language: new_language }
    
    assert_redirected_to clinic_url(@clinic)
    @clinic.reload
    assert_includes @clinic.languages_spoken, new_language
  end

  test "should remove language from clinic" do
    language_to_remove = @clinic.languages_spoken.first
    delete clinic_remove_language_url(@clinic), params: { language: language_to_remove }
    
    assert_redirected_to clinic_url(@clinic)
    @clinic.reload
    assert_not_includes @clinic.languages_spoken, language_to_remove
  end

  # Search and Filter Tests
  test "should search clinics by name" do
    get clinics_url, params: { search: @clinic.name.split.first }
    assert_response :success
    assert_includes @response.body, @clinic.name
  end

  test "should filter clinics by status" do
    get clinics_url, params: { status: "active" }
    assert_response :success
  end

  test "should filter clinics by walk-in availability" do
    get clinics_url, params: { walk_in: true }
    assert_response :success
  end

  test "should filter clinics by number of doctors" do
    get clinics_url, params: { min_doctors: 2 }
    assert_response :success
  end

  # API/JSON Response Tests
  test "should get index as JSON" do
    get clinics_url, as: :json
    assert_response :success
    
    json_response = JSON.parse(@response.body)
    assert json_response.is_a?(Array)
    assert json_response.any? { |c| c["name"] == @clinic.name }
  end

  test "should show clinic as JSON" do
    get clinic_url(@clinic), as: :json
    assert_response :success
    
    json_response = JSON.parse(@response.body)
    assert_equal @clinic.name, json_response["name"]
    assert_equal @clinic.facility_type, json_response["facility_type"]
    assert_equal @clinic.services, json_response["services"]
  end

  test "should create clinic via JSON" do
    assert_difference("Clinic.count") do
      post clinics_url, params: { clinic: @valid_attributes }, as: :json
    end

    assert_response :created
    json_response = JSON.parse(@response.body)
    assert_equal @valid_attributes[:name], json_response["name"]
  end

  test "should update clinic via JSON" do
    patch clinic_url(@clinic), params: { 
      clinic: { name: "Updated via JSON", number_of_doctors: 10 } 
    }, as: :json
    
    assert_response :success
    @clinic.reload
    assert_equal "Updated via JSON", @clinic.name
    assert_equal 10, @clinic.number_of_doctors
  end

  test "should destroy clinic via JSON" do
    assert_difference("Clinic.count", -1) do
      delete clinic_url(@clinic), as: :json
    end

    assert_response :no_content
  end

  # Validation Tests
  test "should validate services array" do
    post clinics_url, params: { 
      clinic: @valid_attributes.merge(services: ["Invalid Service"])
    }
    
    assert_response :unprocessable_entity
    assert_select ".error", text: /not a valid service/
  end

  test "should validate languages array" do
    post clinics_url, params: { 
      clinic: @valid_attributes.merge(languages_spoken: ["InvalidLanguage"])
    }
    
    assert_response :unprocessable_entity
    assert_select ".error", text: /not a valid language/
  end

  # Error Handling Tests
  test "should handle invalid JSON requests gracefully" do
    post clinics_url, params: "invalid json", as: :json
    assert_response :bad_request
  end

  test "should require authentication for create actions" do
    # This test assumes authentication will be implemented
    # post clinics_url, params: { clinic: @valid_attributes }
    # assert_redirected_to login_url
  end

  test "should require admin privileges for destroy actions" do
    # This test assumes authorization will be implemented
    # delete clinic_url(@clinic)
    # assert_response :forbidden
  end
end
