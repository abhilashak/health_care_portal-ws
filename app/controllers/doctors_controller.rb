class DoctorsController < ApplicationController
  before_action :set_doctor, only: [ :show, :edit, :update, :destroy, :appointments, :upcoming_appointments, :past_appointments, :schedule, :availability, :statistics, :patients, :book_appointment, :cancel_appointment ]

  def index
    @doctors = Doctor.includes(:hospital, :clinic, :appointments)

    # Search functionality
    if params[:search].present?
      @doctors = @doctors.where("first_name ILIKE ? OR last_name ILIKE ? OR specialization ILIKE ?",
                               "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%")
    end

    # Filter by specialization
    if params[:specialization].present?
      @doctors = @doctors.where(specialization: params[:specialization])
    end

    # Filter by hospital
    if params[:hospital_id].present?
      @doctors = @doctors.where(hospital_id: params[:hospital_id])
    end

    # Filter by clinic
    if params[:clinic_id].present?
      @doctors = @doctors.where(clinic_id: params[:clinic_id])
    end

    # Filter by experience
    if params[:min_experience].present?
      @doctors = @doctors.where("years_of_experience >= ?", params[:min_experience].to_i)
    end

    # Filter by availability
    if params[:available_date].present?
      date = Date.parse(params[:available_date])
      busy_doctor_ids = Appointment.where(appointment_date: date.beginning_of_day..date.end_of_day)
                                  .where(status: [ "scheduled", "confirmed" ])
                                  .pluck(:doctor_id)
      @doctors = @doctors.where.not(id: busy_doctor_ids)
    end

    # Filter by workplace
    if params[:works_at] == "hospital"
      @doctors = @doctors.where.not(hospital_id: nil)
    elsif params[:works_at] == "clinic"
      @doctors = @doctors.where.not(clinic_id: nil)
    end

    respond_to do |format|
      format.html
      format.json { render json: @doctors }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: @doctor }
    end
  end

  def new
    @doctor = Doctor.new
  end

  def create
    @doctor = Doctor.new(doctor_params)

    respond_to do |format|
      if @doctor.save
        format.html { redirect_to @doctor, notice: "Doctor was successfully created." }
        format.json { render json: @doctor, status: :created }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @doctor.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
  end

  def update
    respond_to do |format|
      if @doctor.update(doctor_params)
        format.html { redirect_to @doctor, notice: "Doctor was successfully updated." }
        format.json { render json: @doctor }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @doctor.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    if @doctor.appointments.upcoming.exists?
      redirect_to @doctor, alert: "Doctor cannot be deleted because they have upcoming appointments."
      return
    end

    @doctor.destroy
    respond_to do |format|
      format.html { redirect_to doctors_url, notice: "Doctor was successfully deleted." }
      format.json { head :no_content }
    end
  end

  # Custom actions
  def appointments
    @appointments = @doctor.appointments.includes(:patient).order(:appointment_date)
    respond_to do |format|
      format.html
      format.json { render json: @appointments }
    end
  end

  def upcoming_appointments
    @upcoming_appointments = @doctor.appointments.upcoming.includes(:patient)
    respond_to do |format|
      format.html
      format.json { render json: @upcoming_appointments }
    end
  end

  def past_appointments
    @past_appointments = @doctor.appointments.past.includes(:patient)
    respond_to do |format|
      format.html
      format.json { render json: @past_appointments }
    end
  end

  def schedule
    date = params[:date] ? Date.parse(params[:date]) : Date.current
    @schedule = @doctor.appointments.where(appointment_date: date.beginning_of_day..date.end_of_day)
                     .includes(:patient).order(:appointment_date)
    respond_to do |format|
      format.html
      format.json { render json: @schedule }
    end
  end

  def availability
    start_date = params[:start_date] ? Date.parse(params[:start_date]) : Date.current
    end_date = params[:end_date] ? Date.parse(params[:end_date]) : start_date + 7.days

    busy_slots = @doctor.appointments.where(appointment_date: start_date..end_date)
                       .where(status: [ "scheduled", "confirmed" ])
                       .pluck(:appointment_date, :duration_minutes)

    @availability = {
      start_date: start_date,
      end_date: end_date,
      busy_slots: busy_slots
    }

    respond_to do |format|
      format.html
      format.json { render json: @availability }
    end
  end

  def statistics
    @stats = {
      total_appointments: @doctor.appointments.count,
      completed_appointments: @doctor.appointments.completed.count,
      upcoming_appointments: @doctor.appointments.upcoming.count,
      unique_patients: @doctor.appointments.joins(:patient).distinct.count("patients.id"),
      years_of_experience: @doctor.years_of_experience,
      specialization: @doctor.specialization
    }
    respond_to do |format|
      format.html
      format.json { render json: @stats }
    end
  end

  def patients
    @patients = Patient.joins(:appointments)
                      .where(appointments: { doctor: @doctor })
                      .distinct
                      .includes(:appointments)
    respond_to do |format|
      format.html
      format.json { render json: @patients }
    end
  end

  def book_appointment
    @appointment = @doctor.appointments.build(appointment_params)

    if @appointment.save
      redirect_to @doctor, notice: "Appointment was successfully booked."
    else
      redirect_to @doctor, alert: "Failed to book appointment: #{@appointment.errors.full_messages.join(', ')}"
    end
  end

  def cancel_appointment
    @appointment = @doctor.appointments.find(params[:appointment_id])
    @appointment.update(status: "cancelled")
    redirect_to @doctor, notice: "Appointment was cancelled."
  end

  private

  def set_doctor
    @doctor = Doctor.find(params[:id])
  end

  def doctor_params
    params.require(:doctor).permit(
      :first_name, :last_name, :specialization, :hospital_id, :clinic_id,
      :phone, :email, :license_number, :years_of_experience
    )
  end

  def appointment_params
    params.require(:appointment).permit(
      :patient_id, :appointment_date, :duration_minutes, :notes, :appointment_type
    )
  end
end
