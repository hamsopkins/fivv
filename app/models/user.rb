class User < ApplicationRecord
	has_secure_password

	validates :name, length: {in: 2..36}
	validates :phone, { presence: true,
											uniqueness: {message: "already taken"},
											format: { with: /\A[^01]\d{9}\z/,
																message: "not a valid phone number"}}
	validates :time_zone, presence: true	
	has_many :contacts
	has_many :conferences
	has_many :conference_contacts, through: :conferences
end
