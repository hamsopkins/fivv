class Contact < ApplicationRecord
	belongs_to :user
	validates_presence_of :user
	validates :name, length: { in: 2..36,
														 message: "too short or too long" }
	validates :phone, uniqueness: { scope: :user,
																	message: "taken by another of your contacts" }
	validates :time_zone, presence: true
	has_many :conference_contacts
	has_many :conferences, through: :conference_contacts

end
