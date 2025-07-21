class PatientsController < ApplicationController
  before_action :set_patient, only: [ :show, :edit, :update, :destroy, :appointments, :upcoming_appointments, :medical_history, :doctors, :update_medical_history, :add_medication, :remove_medication, :book_appointment, :cancel_appointment, :reschedule_appointment ]

  def index
    @patients = Patient.includes(:appointments)

    # Search functionality
    if params[:search].present?
      @patients = @patients.where("first_name ILIKE ? OR last_name ILIKE ? OR email ILIKE ?",
                                 "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%")
    end

    # Filter by email
    if params[:email].present?
      @patients = @patients.where(email: params[:email])
    end

    # Filter by age group
    if params[:age_group].present?
      case params[:age_group]
      when "minor"
        @patients = @patients.where("date_of_birth > ?", 18.years.ago)
      when "adult"
        @patients = @patients.where("date_of_birth BETWEEN ? AND ?", 65.years.ago, 18.years.ago)
      when "senior"
        @patients = @patients.where("date_of_birth < ?", 65.years.ago)
      end
    end

    # Filter by birth year
    if params[:birth_year].present?
      year = params[:birth_year].to_i
      @patients = @patients.where("EXTRACT(YEAR FROM date_of_birth) = ?", year)
    end

    # Filter by insurance provider
    if params[:insurance].present?
      @patients = @patients.where("insurance_provider ILIKE ?", "%#{params[:insurance]}%")
    end

    # Filter patients with recent appointments
    if params[:recent_appointments].present?
      recent_patient_ids = Appointment.where("appointment_date >= ?", 30.days.ago)
                                     .pluck(:patient_id).uniq
      @patients = @patients.where(id: recent_patient_ids)
    end

    respond_to do |format|
      format.html
      format.json { render json: @patients.map { |p| patient_json(p) } }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: patient_json(@patient) }
    end
  end

  def new
    @patient = Patient.new
  end

  def create
    @patient = Patient.new(patient_params)

    respond_to do |format|
      if @patient.save
        format.html { redirect_to @patient, notice: "Patient was successfully created." }
        format.json { render json: patient_json(@patient), status: :created }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @patient.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
  end

  def update
    respond_to do |format|
      if @patient.update(patient_params)
        format.html { redirect_to @patient, notice: "Patient was successfully updated." }
        format.json { render json: patient_json(@patient) }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @patient.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    if @patient.appointments.upcoming.exists?
      redirect_to @patient, alert: "Patient cannot be deleted because they have upcoming appointments."
      return
    end

    @patient.destroy
    respond_to do |format|
      format.html { redirect_to patients_url, notice: "Patient was successfully deleted." }
      format.json { head :no_content }
    end
  end

  # Custom actions
  def appointments
    @appointments = @patient.appointments.includes(:doctor).order(:appointment_date)
    respond_to do |format|
      format.html
      format.json { render json: @appointments }
    end
  end

  def upcoming_appointments
    @upcoming_appointments = @patient.appointments.upcoming.includes(:doctor)
    respond_to do |format|
      format.html
      format.json { render json: @upcoming_appointments }
    end
  end

  def medical_history
    @medical_history = @patient.medical_history
    respond_to do |format|
      format.html
      format.json { render json: { medical_history: @medical_history } }
    end
  end

  def doctors
    @doctors = Doctor.joins(:appointments)
                    .where(appointments: { patient: @patient })
                    .distinct
                    .includes(:hospital, :clinic)
    respond_to do |format|
      format.html
      format.json { render json: @doctors }
    end
  end

  def update_medical_history
    new_history = params[:medical_history]
    if new_history.present?
      current_history = @patient.medical_history || ""
      updated_history = current_history.present? ? "#{current_history}\n\n#{new_history}" : new_history
      @patient.update(medical_history: updated_history)
    end
    redirect_to @patient
  end

  def add_medication
    medication = params[:medication]
    if medication.present? && !@patient.current_medications&.include?(medication)
      @patient.current_medications = (@patient.current_medications || []) + [ medication ]
      @patient.save
    end
    redirect_to @patient
  end

  def remove_medication
    medication = params[:medication]
    if medication.present? && @patient.current_medications&.include?(medication)
      @patient.current_medications = @patient.current_medications - [ medication ]
      @patient.save
    end
    redirect_to @patient
  end

  def book_appointment
    @appointment = @patient.appointments.build(appointment_params)

    if @appointment.save
      redirect_to @patient, notice: "Appointment was successfully booked."
    else
      redirect_to @patient, alert: "Failed to book appointment: #{@appointment.errors.full_messages.join(', ')}"
    end
  end

  def cancel_appointment
    @appointment = @patient.appointments.find(params[:appointment_id])
    @appointment.update(status: "cancelled")
    redirect_to @patient, notice: "Appointment was cancelled."
  end

  def reschedule_appointment
    @appointment = @patient.appointments.find(params[:appointment_id])
    if @appointment.update(appointment_params)
      redirect_to @patient, notice: "Appointment was rescheduled."
    else
      redirect_to @patient, alert: "Failed to reschedule: #{@appointment.errors.full_messages.join(', ')}"
    end
  end

  private

  def set_patient
    @patient = Patient.find(params[:id])
  end

  def patient_params
    params.require(:patient).permit(
      :first_name, :last_name, :date_of_birth, :email, :phone, :address,
      :emergency_contact_name, :emergency_contact_phone, :insurance_provider,
      :insurance_policy_number, :medical_history, current_medications: []
    )
  end

  def appointment_params
    params.require(:appointment).permit(
      :doctor_id, :appointment_date, :duration_minutes, :notes, :appointment_type
    )
  end

  # Helper method to return patient data with masked sensitive information for JSON
  def patient_json(patient)
    patient.as_json.tap do |json|
      json["age"] = patient.age
      # Mask sensitive information in JSON responses
      if json["insurance_policy_number"].present?
        json["insurance_policy_number"] = "***#{json['insurance_policy_number'][-4..-1]}"
      end
    end
  end
end
