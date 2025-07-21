class ClinicsController < ApplicationController
  before_action :set_clinic, only: [ :show, :edit, :update, :destroy, :doctors, :services, :walk_in_hours, :appointment_hours, :add_service, :remove_service, :add_language, :remove_language ]

  def index
    @clinics = Clinic.includes(:doctors)

    # Search functionality
    if params[:search].present?
      @clinics = @clinics.where("name ILIKE ? OR address ILIKE ?", "%#{params[:search]}%", "%#{params[:search]}%")
    end

    # Filter by clinic type
    if params[:clinic_type].present?
      @clinics = @clinics.where(facility_type: params[:clinic_type])
    end

    # Filter by services
    if params[:service].present?
      @clinics = @clinics.where("services @> ?", [ params[:service] ].to_json)
    end

    # Filter by languages
    if params[:language].present?
      @clinics = @clinics.where("languages_spoken @> ?", [ params[:language] ].to_json)
    end

    # Filter by status
    if params[:status].present?
      @clinics = @clinics.where(status: params[:status])
    end

    # Filter by walk-in availability
    if params[:walk_in].present?
      @clinics = @clinics.where("operating_hours ? 'walk_in'")
    end

    # Filter by minimum number of doctors
    if params[:min_doctors].present?
      @clinics = @clinics.where("number_of_doctors >= ?", params[:min_doctors].to_i)
    end

    respond_to do |format|
      format.html
      format.json { render json: @clinics }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: @clinic }
    end
  end

  def new
    @clinic = Clinic.new
  end

  def create
    @clinic = Clinic.new(clinic_params)

    respond_to do |format|
      if @clinic.save
        format.html { redirect_to @clinic, notice: "Clinic was successfully created." }
        format.json { render json: @clinic, status: :created }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @clinic.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
  end

  def update
    respond_to do |format|
      if @clinic.update(clinic_params)
        format.html { redirect_to @clinic, notice: "Clinic was successfully updated." }
        format.json { render json: @clinic }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @clinic.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    if @clinic.doctors.exists?
      redirect_to @clinic, alert: "Clinic cannot be deleted because it has associated doctors."
      return
    end

    @clinic.destroy
    respond_to do |format|
      format.html { redirect_to clinics_url, notice: "Clinic was successfully deleted." }
      format.json { head :no_content }
    end
  end

  # Custom actions
  def doctors
    @doctors = @clinic.doctors.includes(:appointments)
    respond_to do |format|
      format.html
      format.json { render json: @doctors }
    end
  end

  def services
    @services = @clinic.services || []
    respond_to do |format|
      format.html
      format.json { render json: @services }
    end
  end

  def walk_in_hours
    @walk_in_hours = @clinic.operating_hours&.dig("walk_in")
    respond_to do |format|
      format.html
      format.json { render json: { walk_in_hours: @walk_in_hours } }
    end
  end

  def appointment_hours
    @appointment_hours = @clinic.operating_hours&.except("walk_in")
    respond_to do |format|
      format.html
      format.json { render json: { appointment_hours: @appointment_hours } }
    end
  end

  def add_service
    service = params[:service]
    if service.present? && !@clinic.services&.include?(service)
      @clinic.services = (@clinic.services || []) + [ service ]
      @clinic.save
    end
    redirect_to @clinic
  end

  def remove_service
    service = params[:service]
    if service.present? && @clinic.services&.include?(service)
      @clinic.services = @clinic.services - [ service ]
      @clinic.save
    end
    redirect_to @clinic
  end

  def add_language
    language = params[:language]
    if language.present? && !@clinic.languages_spoken&.include?(language)
      @clinic.languages_spoken = (@clinic.languages_spoken || []) + [ language ]
      @clinic.save
    end
    redirect_to @clinic
  end

  def remove_language
    language = params[:language]
    if language.present? && @clinic.languages_spoken&.include?(language)
      @clinic.languages_spoken = @clinic.languages_spoken - [ language ]
      @clinic.save
    end
    redirect_to @clinic
  end

  private

  def set_clinic
    @clinic = Clinic.find(params[:id])
  end

  def clinic_params
    params.require(:clinic).permit(
      :name, :address, :phone, :email, :registration_number, :facility_type,
      :number_of_doctors, :status,
      operating_hours: {}, services: [], languages_spoken: []
    )
  end
end
