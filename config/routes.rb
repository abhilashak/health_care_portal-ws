Rails.application.routes.draw do
  # Root route
  root "home#index"
  get "home/index"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by uptime monitors and load balancers.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Healthcare Portal Routes
  root "hospitals#index"

  # Hospital routes with custom actions
  resources :hospitals do
    member do
      get :doctors
      get :emergency_services
      get :specialties
      get :statistics
      post :add_service
      delete :remove_service
    end
    collection do
      get :search
    end
  end

  # Clinic routes with custom actions
  resources :clinics do
    member do
      get :doctors
      get :services
      get :walk_in_hours
      get :appointment_hours
      post :add_service
      delete :remove_service
      post :add_language
      delete :remove_language
    end
  end

  # Doctor routes with custom actions
  resources :doctors do
    member do
      get :appointments
      get :upcoming_appointments
      get :past_appointments
      get :schedule
      get :availability
      get :statistics
      get :patients
      post :book_appointment
      patch :cancel_appointment
    end

    # Nested appointments routes
    resources :appointments, except: [ :index ], controller: "appointments"
  end

  # Patient routes with custom actions
  resources :patients do
    member do
      get :appointments
      get :upcoming_appointments
      get :medical_history
      get :doctors
      patch :update_medical_history
      post :add_medication
      delete :remove_medication
      post :book_appointment
      patch :cancel_appointment
      patch :reschedule_appointment
    end
  end

  # Appointment routes with custom actions
  resources :appointments do
    member do
      patch :confirm
      patch :cancel
      patch :complete
      patch :reschedule
      get :conflicts
    end
    collection do
      get :todays, to: "appointments#todays"
      get :upcoming
      get :by_date, to: "appointments#by_date"
      get :statistics
      get :calendar
      get :available_slots
      get "doctor_schedule/:doctor_id", to: "appointments#doctor_schedule", as: :doctor_schedule
      get "patient_history/:patient_id", to: "appointments#patient_history", as: :patient_appointment_history
    end
  end
end
