class HospitalsController < ApplicationController
  before_action :set_hospital, only: [ :show, :edit, :update, :destroy, :doctors, :emergency_services, :specialties, :statistics, :add_service, :remove_service ]

  def index
    @hospitals = Hospital.includes(:doctors)

    # Search functionality
    if params[:search].present?
      @hospitals = @hospitals.where("name ILIKE ? OR address ILIKE ?", "%#{params[:search]}%", "%#{params[:search]}%")
    end

    # Filter by hospital type
    if params[:hospital_type].present?
      @hospitals = @hospitals.where(facility_type: params[:hospital_type])
    end

    # Filter by services
    if params[:service].present?
      @hospitals = @hospitals.where("services @> ?", [ params[:service] ].to_json)
    end

    # Filter by emergency services
    if params[:emergency].present?
      @hospitals = @hospitals.where(emergency_services: true)
    end

    # Filter by status
    if params[:status].present?
      @hospitals = @hospitals.where(status: params[:status])
    end

    respond_to do |format|
      format.html
      format.json { render json: @hospitals }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: @hospital }
    end
  end

  def new
    @hospital = Hospital.new
  end

  def create
    @hospital = Hospital.new(hospital_params)

    respond_to do |format|
      if @hospital.save
        format.html { redirect_to @hospital, notice: "Hospital was successfully created." }
        format.json { render json: @hospital, status: :created }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @hospital.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
  end

  def update
    respond_to do |format|
      if @hospital.update(hospital_params)
        format.html { redirect_to @hospital, notice: "Hospital was successfully updated." }
        format.json { render json: @hospital }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @hospital.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    if @hospital.doctors.exists?
      redirect_to @hospital, alert: "Hospital cannot be deleted because it has associated doctors."
      return
    end

    @hospital.destroy
    respond_to do |format|
      format.html { redirect_to hospitals_url, notice: "Hospital was successfully deleted." }
      format.json { head :no_content }
    end
  end

  # Custom actions
  def doctors
    @doctors = @hospital.doctors.includes(:appointments)
    respond_to do |format|
      format.html
      format.json { render json: @doctors }
    end
  end

  def emergency_services
    respond_to do |format|
      format.html
      format.json { render json: { emergency_services: @hospital.emergency_services } }
    end
  end

  def specialties
    @specialties = @hospital.doctors.distinct.pluck(:specialization).compact
    respond_to do |format|
      format.html
      format.json { render json: @specialties }
    end
  end

  def statistics
    @stats = {
      total_doctors: @hospital.doctors.count,
      total_beds: @hospital.number_of_beds,
      emergency_services: @hospital.emergency_services,
      services_count: @hospital.services&.count || 0
    }
    respond_to do |format|
      format.html
      format.json { render json: @stats }
    end
  end

  def add_service
    service = params[:service]
    if service.present? && !@hospital.services&.include?(service)
      @hospital.services = (@hospital.services || []) + [ service ]
      @hospital.save
    end
    redirect_to @hospital
  end

  def remove_service
    service = params[:service]
    if service.present? && @hospital.services&.include?(service)
      @hospital.services = @hospital.services - [ service ]
      @hospital.save
    end
    redirect_to @hospital
  end

  def search
    @hospitals = Hospital.where("name ILIKE ? OR address ILIKE ?", "%#{params[:q]}%", "%#{params[:q]}%")
    respond_to do |format|
      format.html { render :index }
      format.json { render json: @hospitals }
    end
  end

  private

  def set_hospital
    @hospital = Hospital.find(params[:id])
  end

  def hospital_params
    params.require(:hospital).permit(
      :name, :address, :phone, :email, :registration_number, :facility_type,
      :number_of_beds, :emergency_services, :trauma_center_level, :status,
      operating_hours: {}, services: [], languages_spoken: []
    )
  end
end
