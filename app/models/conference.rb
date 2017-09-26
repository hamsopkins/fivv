class Conference < ApplicationRecord
	belongs_to :user
	validates_presence_of :user
	validates :start_time, presence: true
	validates :end_time, presence: true
	validate :are_times_logical
	validates :admin_pin, presence: true
	validates :name, length: { in: 3..20,
														 message: "is too long or too short"}
	has_many :conference_contacts
	has_many :contacts, through: :conference_contacts
	validate :exceeds_max_per_user?
	validate :exceeds_max_participants?

	def exceeds_max_per_user?
		errors.add(:base, "exceeds maximum number of conferences allowed in demo mode") if self.user.conferences.count >= 5
	end

	def exceeds_max_participants?
		max_participants = 250
		if ENV["MAX_PARTICIPANTS"]
			max_participants = ENV["MAX_PARTICIPANTS"].to_i if (2..250).include?(ENV["MAX_PARTICIPANTS"].to_i)
		end
		errors.add(:base, "exceeds maximum participants") if self.conference_contacts.count + 1 > max_participants
	end

	def pin
		BCrypt::Password.new(self.admin_pin)
	end

	def authenticate(entered_pin)
		self.pin == entered_pin
	end

	def set_pin
		proposed_pin = rand.to_s[2..7]
		if self.persisted?
			if self.conference_contacts.any? {|c| c.authenticate(proposed_pin) }
				until self.conference_contacts.none? {|c| c.authenticate(proposed_pin) }
					proposed_pin = rand.to_s[2..7]
				end
			end
		end
		self.admin_pin = BCrypt::Password.create(proposed_pin)
		self.save
		proposed_pin
	end

	def are_times_logical
		if end_time - start_time < 300 || end_time - start_time > 900
			errors.add(:end_time, "must be at least 5 minutes and no more than 15 minutes after start time")
		end
		if start_time < Time.now + 600
			errors.add(:start_time, "must be at least 10 minutes from now")
		end
		if self.user.expiration
			if end_time > self.user.expiration
				errors.add(:end_time, "must be before user account expires")
			end
		end
	end

	def inform_admin(pin)
    greeting = "Hi #{self.user.name}, you have successfully created the conference #{self.name}. Please call this number on #{pretty_time(self.start_time)}."
		pin_msg = "Conference code: #{self.access_code}\nAdmin PIN: #{pin}"
		client = Twilio::REST::Client.new ENV["TWILIO_SID"], ENV["TWILIO_AUTH_TOKEN"]
		client.messages.create(
			from: ENV["TWILIO_NUMBER"],
			to: "+1#{self.user.phone}",
			body: "#{greeting}\n\n#{pin_msg}"
			)
	end

	def remove_access_code
		self.update_attribute(:access_code, nil)
	end

	def pretty_time(time_obj)
		time_obj.in_time_zone(self.user.time_zone).strftime('%b %d %Y at %l:%M %p %Z')
	end
end
