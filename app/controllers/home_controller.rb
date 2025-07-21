class HomeController < ApplicationController
  def index
    @search_query = params[:search]&.strip

    # Get hospitals with optional search
    @hospitals = if @search_query.present?
      Hospital.where("name ILIKE ? OR address ILIKE ? OR city ILIKE ?",
                     "%#{@search_query}%", "%#{@search_query}%", "%#{@search_query}%")
              .order(:name)
    else
      Hospital.order(:name)
    end

    # Get clinics with optional search
    @clinics = if @search_query.present?
      Clinic.where("name ILIKE ? OR address ILIKE ? OR city ILIKE ?",
                   "%#{@search_query}%", "%#{@search_query}%", "%#{@search_query}%")
             .order(:name)
    else
      Clinic.order(:name)
    end

    # Statistics for the header
    @total_hospitals = Hospital.count
    @total_clinics = Clinic.count
    @total_doctors = Doctor.count
    @total_patients = Patient.count
  end
end
