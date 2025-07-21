# frozen_string_literal: true

require "test_helper"

class HospitalsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @hospital = healthcare_facilities(:general_hospital)
    @valid_attributes = {
      name: "New General Hospital",
      address: "123 Medical Center Dr\nHealthcare City, HC 12345",
      phone: "+1-555-123-4567",
      email: "info@newgeneral.com",
      registration_number: "REG987654",
      facility_type: "general",
      operating_hours: { "monday" => "8:00-18:00", "tuesday" => "8:00-18:00" },
      status: "active",
      emergency_contact: "Emergency Department",
      emergency_phone: "+1-555-911-0000"
    }
    @invalid_attributes = {
      name: "",
      address: "",
      phone: "invalid-phone",
      email: "invalid-email",
      registration_number: "",
      facility_type: "invalid_type"
    }
  end

  # Index Tests
  test "should get index" do
    get hospitals_url
    assert_response :success
    assert_not_nil assigns(:hospitals)
    assert_includes @response.body, @hospital.name
  end

  test "should get index with search parameter" do
    get hospitals_url, params: { search: @hospital.name }
    assert_response :success
    assert_includes @response.body, @hospital.name
  end

  test "should get index filtered by hospital type" do
    get hospitals_url, params: { hospital_type: @hospital.facility_type }
    assert_response :success
  end

  test "should get index with pagination" do
    get hospitals_url, params: { page: 1 }
    assert_response :success
  end

  # Show Tests
  test "should show hospital" do
    get hospital_url(@hospital)
    assert_response :success
    assert_includes @response.body, @hospital.name
    assert_includes @response.body, @hospital.address
  end

  test "should show hospital with doctors" do
    get hospital_url(@hospital)
    assert_response :success
    # Should display associated doctors
    @hospital.doctors.each do |doctor|
      assert_includes @response.body, doctor.full_name
    end
  end

  test "should return 404 for non-existent hospital" do
    assert_raises(ActiveRecord::RecordNotFound) do
      get hospital_url(id: 99999)
    end
  end

  # New Tests
  test "should get new" do
    get new_hospital_url
    assert_response :success
    assert_select "form[action=?]", hospitals_path
  end

  # Create Tests
  test "should create hospital with valid attributes" do
    assert_difference("Hospital.count") do
      post hospitals_url, params: { hospital: @valid_attributes }
    end

    hospital = Hospital.last
    assert_redirected_to hospital_url(hospital)
    assert_equal @valid_attributes[:name], hospital.name
    assert_equal @valid_attributes[:facility_type], hospital.facility_type
  end

  test "should not create hospital with invalid attributes" do
    assert_no_difference("Hospital.count") do
      post hospitals_url, params: { hospital: @invalid_attributes }
    end

    assert_response :unprocessable_entity
    assert_select ".error", text: /can't be blank/
  end

  test "should not create hospital with duplicate name" do
    duplicate_attributes = @valid_attributes.merge(name: @hospital.name)
    
    assert_no_difference("Hospital.count") do
      post hospitals_url, params: { hospital: duplicate_attributes }
    end

    assert_response :unprocessable_entity
    assert_select ".error", text: /has already been taken/
  end

  # Edit Tests
  test "should get edit" do
    get edit_hospital_url(@hospital)
    assert_response :success
    assert_select "form[action=?]", hospital_path(@hospital)
    assert_select "input[value=?]", @hospital.name
  end

  # Update Tests
  test "should update hospital with valid attributes" do
    new_name = "Updated Hospital Name"
    patch hospital_url(@hospital), params: { 
      hospital: { name: new_name, facility_type: "teaching" } 
    }
    
    assert_redirected_to hospital_url(@hospital)
    @hospital.reload
    assert_equal new_name, @hospital.name
    assert_equal "teaching", @hospital.facility_type
  end

  test "should not update hospital with invalid attributes" do
    original_name = @hospital.name
    patch hospital_url(@hospital), params: { 
      hospital: { name: "", email: "invalid-email" } 
    }
    
    assert_response :unprocessable_entity
    @hospital.reload
    assert_equal original_name, @hospital.name
  end

  test "should not update hospital with duplicate name" do
    other_hospital = healthcare_facilities(:childrens_hospital)
    original_name = @hospital.name
    
    patch hospital_url(@hospital), params: { 
      hospital: { name: other_hospital.name } 
    }
    
    assert_response :unprocessable_entity
    @hospital.reload
    assert_equal original_name, @hospital.name
  end

  # Destroy Tests
  test "should destroy hospital" do
    assert_difference("Hospital.count", -1) do
      delete hospital_url(@hospital)
    end

    assert_redirected_to hospitals_url
  end

  test "should not destroy hospital with associated doctors" do
    # Create a doctor associated with the hospital
    doctor = doctors(:cardiologist)
    doctor.update!(hospital: @hospital)
    
    assert_no_difference("Hospital.count") do
      delete hospital_url(@hospital)
    end

    assert_redirected_to hospital_url(@hospital)
    assert_match /cannot be deleted.*associated doctors/, flash[:alert]
  end

  # Custom Endpoints Tests
  test "should get hospital doctors" do
    get hospital_doctors_url(@hospital)
    assert_response :success
    assert_not_nil assigns(:doctors)
  end

  test "should get hospital specialties" do
    get hospital_specialties_url(@hospital)
    assert_response :success
    assert_not_nil assigns(:specialties)
  end

  test "should get hospital emergency_services" do
    get hospital_emergency_services_url(@hospital)
    assert_response :success
  end

  test "should get hospital statistics" do
    get hospital_statistics_url(@hospital)
    assert_response :success
    assert_not_nil assigns(:stats)
  end

  # Search and Filter Tests
  test "should search hospitals by name" do
    get hospitals_url, params: { search: @hospital.name.split.first }
    assert_response :success
    assert_includes @response.body, @hospital.name
  end

  test "should filter hospitals by status" do
    get hospitals_url, params: { status: "active" }
    assert_response :success
  end

  test "should filter hospitals by emergency services" do
    get hospitals_url, params: { emergency_services: true }
    assert_response :success
  end

  # API/JSON Response Tests
  test "should get index as JSON" do
    get hospitals_url, as: :json
    assert_response :success
    
    json_response = JSON.parse(@response.body)
    assert json_response.is_a?(Array)
    assert json_response.any? { |h| h["name"] == @hospital.name }
  end

  test "should show hospital as JSON" do
    get hospital_url(@hospital), as: :json
    assert_response :success
    
    json_response = JSON.parse(@response.body)
    assert_equal @hospital.name, json_response["name"]
    assert_equal @hospital.facility_type, json_response["facility_type"]
  end

  test "should create hospital via JSON" do
    assert_difference("Hospital.count") do
      post hospitals_url, params: { hospital: @valid_attributes }, as: :json
    end

    assert_response :created
    json_response = JSON.parse(@response.body)
    assert_equal @valid_attributes[:name], json_response["name"]
  end

  test "should update hospital via JSON" do
    patch hospital_url(@hospital), params: { 
      hospital: { name: "Updated via JSON" } 
    }, as: :json
    
    assert_response :success
    @hospital.reload
    assert_equal "Updated via JSON", @hospital.name
  end

  test "should destroy hospital via JSON" do
    assert_difference("Hospital.count", -1) do
      delete hospital_url(@hospital), as: :json
    end

    assert_response :no_content
  end

  # Error Handling Tests
  test "should handle invalid JSON requests gracefully" do
    post hospitals_url, params: "invalid json", as: :json
    assert_response :bad_request
  end

  test "should require authentication for create actions" do
    # This test assumes authentication will be implemented
    # post hospitals_url, params: { hospital: @valid_attributes }
    # assert_redirected_to login_url
  end

  test "should require admin privileges for destroy actions" do
    # This test assumes authorization will be implemented
    # delete hospital_url(@hospital)
    # assert_response :forbidden
  end
end
