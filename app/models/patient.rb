# frozen_string_literal: true

class Patient < ApplicationRecord
  # Associations
  has_many :appointments, dependent: :destroy

  # Validations
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :date_of_birth, presence: true
  validates :email, presence: true, uniqueness: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a valid email address" }

  # Scopes
  scope :search_by_name, ->(query) { where("first_name ILIKE ? OR last_name ILIKE ?", "%#{query}%", "%#{query}%") }
  scope :search_by_email, ->(query) { where("email ILIKE ?", "%#{query}%") }
  scope :born_after, ->(date) { where("date_of_birth > ?", date) }
  scope :born_before, ->(date) { where("date_of_birth < ?", date) }

  # Callbacks
  before_validation :normalize_names
  before_save :normalize_email

  # Instance Methods
  def full_name
    "#{first_name} #{last_name}".strip
  end

  def age
    return nil unless date_of_birth

    today = Date.current
    age = today.year - date_of_birth.year
    age -= 1 if today < date_of_birth + age.years
    age
  end

  def adult?
    age && age >= 18
  end

  def minor?
    age && age < 18
  end

  def senior?
    age && age >= 65
  end

  private

  def normalize_names
    self.first_name = first_name.to_s.strip.titleize if first_name.present?
    self.last_name = last_name.to_s.strip.titleize if last_name.present?
  end

  def normalize_email
    self.email = email.to_s.downcase.strip if email.present?
  end
end
