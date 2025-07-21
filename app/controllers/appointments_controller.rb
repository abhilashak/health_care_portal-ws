class AppointmentsController < ApplicationController
  before_action :set_appointment, only: [ :show, :edit, :update, :destroy, :confirm, :cancel, :complete, :reschedule, :conflicts ]

  def index
    @appointments = Appointment.includes(:doctor, :patient)

    # Filter by date
    if params[:date].present?
      date = Date.parse(params[:date])
      @appointments = @appointments.where(appointment_date: date.beginning_of_day..date.end_of_day)
    end

    # Filter by date range
    if params[:start_date].present? && params[:end_date].present?
      start_date = Date.parse(params[:start_date])
      end_date = Date.parse(params[:end_date])
      @appointments = @appointments.where(appointment_date: start_date..end_date)
    end

    # Filter by status
    if params[:status].present?
      @appointments = @appointments.where(status: params[:status])
    end

    # Filter by doctor
    if params[:doctor_id].present?
      @appointments = @appointments.where(doctor_id: params[:doctor_id])
    end

    # Filter by patient
    if params[:patient_id].present?
      @appointments = @appointments.where(patient_id: params[:patient_id])
    end

    # Filter by appointment type
    if params[:appointment_type].present?
      @appointments = @appointments.where(appointment_type: params[:appointment_type])
    end

    # Filter by duration
    if params[:min_duration].present?
      @appointments = @appointments.where("duration_minutes >= ?", params[:min_duration].to_i)
    end
    if params[:max_duration].present?
      @appointments = @appointments.where("duration_minutes <= ?", params[:max_duration].to_i)
    end

    # Search functionality
    if params[:search].present?
      @appointments = @appointments.joins(:doctor, :patient)
                                  .where("doctors.first_name ILIKE ? OR doctors.last_name ILIKE ? OR patients.first_name ILIKE ? OR patients.last_name ILIKE ?",
                                        "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%")
    end

    @appointments = @appointments.order(:appointment_date)

    respond_to do |format|
      format.html
      format.json { render json: @appointments }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: @appointment }
    end
  end

  def new
    @appointment = Appointment.new
    @appointment.doctor_id = params[:doctor_id] if params[:doctor_id].present?
    @appointment.patient_id = params[:patient_id] if params[:patient_id].present?
  end

  def create
    @appointment = Appointment.new(appointment_params)

    respond_to do |format|
      if @appointment.save
        format.html { redirect_to @appointment, notice: "Appointment was successfully created." }
        format.json { render json: @appointment, status: :created }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    if @appointment.appointment_date < Time.current && @appointment.status == "completed"
      redirect_to @appointment, alert: "Cannot edit past appointments."
    end
  end

  def update
    respond_to do |format|
      if @appointment.update(appointment_params)
        format.html { redirect_to @appointment, notice: "Appointment was successfully updated." }
        format.json { render json: @appointment }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    if @appointment.status == "completed"
      redirect_to @appointment, alert: "Cannot delete completed appointments."
      return
    end

    @appointment.destroy
    respond_to do |format|
      format.html { redirect_to appointments_url, notice: "Appointment was successfully cancelled." }
      format.json { head :no_content }
    end
  end

  # Status management actions
  def confirm
    @appointment.update(status: "confirmed")
    respond_to do |format|
      format.html { redirect_to @appointment, notice: "Appointment was confirmed." }
      format.json { render json: @appointment }
    end
    # Send confirmation email
    # AppointmentMailer.confirmation(@appointment).deliver_later
  end

  def cancel
    @appointment.update(status: "cancelled")
    respond_to do |format|
      format.html { redirect_to @appointment, notice: "Appointment was cancelled." }
      format.json { render json: @appointment }
    end
    # Send cancellation email
    # AppointmentMailer.cancellation(@appointment).deliver_later
  end

  def complete
    @appointment.update(status: "completed")
    respond_to do |format|
      format.html { redirect_to @appointment, notice: "Appointment was marked as completed." }
      format.json { render json: @appointment }
    end
  end

  def reschedule
    if @appointment.update(appointment_params.merge(status: "scheduled"))
      redirect_to @appointment, notice: "Appointment was rescheduled."
    else
      redirect_to @appointment, alert: "Failed to reschedule: #{@appointment.errors.full_messages.join(', ')}"
    end
  end

  def conflicts
    conflicts = Appointment.where(doctor: @appointment.doctor)
                          .where.not(id: @appointment.id)
                          .where(status: [ "scheduled", "confirmed" ])
                          .where(
                            "(appointment_date < ? AND appointment_date + INTERVAL '1 minute' * duration_minutes > ?) OR
                             (appointment_date < ? AND appointment_date + INTERVAL '1 minute' * duration_minutes > ?)",
                            @appointment.appointment_date + @appointment.duration_minutes.minutes,
                            @appointment.appointment_date,
                            @appointment.appointment_date,
                            @appointment.appointment_date + @appointment.duration_minutes.minutes
                          )
                          .includes(:patient)

    respond_to do |format|
      format.html { @conflicts = conflicts }
      format.json { render json: conflicts }
    end
  end

  # Collection actions
  def todays
    @appointments = Appointment.where(appointment_date: Date.current.beginning_of_day..Date.current.end_of_day)
                              .includes(:doctor, :patient)
                              .order(:appointment_date)
    respond_to do |format|
      format.html { render :index }
      format.json { render json: @appointments }
    end
  end

  def upcoming
    @appointments = Appointment.upcoming.includes(:doctor, :patient).order(:appointment_date)
    respond_to do |format|
      format.html { render :index }
      format.json { render json: @appointments }
    end
  end

  def by_date
    date = params[:date] ? Date.parse(params[:date]) : Date.current
    @appointments = Appointment.where(appointment_date: date.beginning_of_day..date.end_of_day)
                              .includes(:doctor, :patient)
                              .order(:appointment_date)
    respond_to do |format|
      format.html { render :index }
      format.json { render json: @appointments }
    end
  end

  def statistics
    @stats = {
      total_appointments: Appointment.count,
      scheduled: Appointment.where(status: "scheduled").count,
      confirmed: Appointment.where(status: "confirmed").count,
      completed: Appointment.where(status: "completed").count,
      cancelled: Appointment.where(status: "cancelled").count,
      today: Appointment.where(appointment_date: Date.current.beginning_of_day..Date.current.end_of_day).count,
      this_week: Appointment.where(appointment_date: Date.current.beginning_of_week..Date.current.end_of_week).count,
      this_month: Appointment.where(appointment_date: Date.current.beginning_of_month..Date.current.end_of_month).count
    }
    respond_to do |format|
      format.html
      format.json { render json: @stats }
    end
  end

  def calendar
    start_date = params[:start] ? Date.parse(params[:start]) : Date.current.beginning_of_month
    end_date = params[:end] ? Date.parse(params[:end]) : Date.current.end_of_month

    appointments = Appointment.where(appointment_date: start_date..end_date)
                             .includes(:doctor, :patient)

    calendar_events = appointments.map do |appointment|
      {
        id: appointment.id,
        title: "#{appointment.patient.full_name} - #{appointment.doctor.full_name}",
        start: appointment.appointment_date.iso8601,
        end: (appointment.appointment_date + appointment.duration_minutes.minutes).iso8601,
        color: status_color(appointment.status)
      }
    end

    respond_to do |format|
      format.json { render json: calendar_events }
    end
  end

  def available_slots
    doctor = Doctor.find(params[:doctor_id])
    date = params[:date] ? Date.parse(params[:date]) : Date.current

    # Get busy slots for the doctor on the specified date
    busy_slots = doctor.appointments.where(appointment_date: date.beginning_of_day..date.end_of_day)
                      .where(status: [ "scheduled", "confirmed" ])
                      .pluck(:appointment_date, :duration_minutes)

    # Generate available slots (simplified - assumes 9 AM to 5 PM, 30-minute slots)
    available_slots = []
    (9..16).each do |hour|
      [ 0, 30 ].each do |minute|
        slot_time = date.beginning_of_day + hour.hours + minute.minutes
        slot_available = busy_slots.none? do |busy_start, duration|
          busy_end = busy_start + duration.minutes
          slot_time >= busy_start && slot_time < busy_end
        end
        available_slots << slot_time if slot_available
      end
    end

    respond_to do |format|
      format.json { render json: available_slots }
    end
  end

  def doctor_schedule
    doctor = Doctor.find(params[:doctor_id])
    date = params[:date] ? Date.parse(params[:date]) : Date.current

    @appointments = doctor.appointments.where(appointment_date: date.beginning_of_day..date.end_of_day)
                         .includes(:patient)
                         .order(:appointment_date)

    respond_to do |format|
      format.html { render :index }
      format.json { render json: @appointments }
    end
  end

  def patient_history
    patient = Patient.find(params[:patient_id])
    @appointments = patient.appointments.includes(:doctor).order(appointment_date: :desc)

    respond_to do |format|
      format.html { render :index }
      format.json { render json: @appointments }
    end
  end

  private

  def set_appointment
    @appointment = Appointment.find(params[:id])
  end

  def appointment_params
    params.require(:appointment).permit(
      :doctor_id, :patient_id, :appointment_date, :duration_minutes,
      :status, :notes, :appointment_type
    )
  end

  def status_color(status)
    case status
    when "scheduled" then "#007bff"
    when "confirmed" then "#28a745"
    when "completed" then "#6c757d"
    when "cancelled" then "#dc3545"
    else "#17a2b8"
    end
  end
end
