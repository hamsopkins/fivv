class ConferenceContact < ApplicationRecord
	belongs_to :conference
	validates_presence_of :conference
	belongs_to :contact
	validates_presence_of :contact
	validates_uniqueness_of :contact, scope: :conference
	validate :exceeds_max_participants

	def exceeds_max_participants
		max_participants = 250
		max_participants = ENV["MAX_PARTICIPANTS"].to_i if ENV["MAX_PARTICIPANTS"]
		errors.add(:base, "exceeds maximum participants") if self.conference.conference_contacts.count + 1 > max_participants
	end

	def pin_hash
		@pin_hash ||= BCrypt::Password.new(pin)
	end

	def authenticate(entered_pin)
		self.pin_hash == entered_pin
	end

	def set_pin
		proposed_pin = rand.to_s[2..7]
		conference = self.conference
		if conference
			if conference.conference_contacts.none?
				self.pin = BCrypt::Password.create(proposed_pin)
			else
				self.pin = BCrypt::Password.create(proposed_pin)
				if conference.conference_contacts.reject { |c| c == self }.any? { |c| c.authenticate(proposed_pin) } || conference.authenticate(proposed_pin)
					until conference.conference_contacts.reject { |c| c == self }.none? { |c| c.authenticate(proposed_pin) } && !conference.authenticate(proposed_pin)
						proposed_pin = rand.to_s[2..7]
					end
				self.pin = BCrypt::Password.create(proposed_pin)
				end
			end
		else
			self.pin = BCrypt::Password.create(proposed_pin)
		end

		if self.save
			self.inform_participant(proposed_pin)
			self
		else
			errors.add(:pin, "500")
		end
	end

	def inform_participant(pin)
		conference = self.conference
		access_code = self.conference.access_code
		contact = self.contact
    greeting = "Hi #{contact.name}, you are invited to the conference #{conference.name} by #{conference.user.name}. Please call this number on #{pretty_time(conference.start_time)}."
		pin_msg = "Conference code: #{access_code}\nYour PIN: #{pin}"
		client = Twilio::REST::Client.new ENV["TWILIO_SID"], ENV["TWILIO_AUTH_TOKEN"]
		client.messages.create(
			from: ENV["TWILIO_NUMBER"],
			to: "+1#{contact.phone}",
			body: "#{greeting}\n\n#{pin_msg}"
			)
	  puts "informed #{contact.name} of #{conference.name}"
	end

	private

	def pretty_time(time_obj)
		time_obj.in_time_zone(self.contact.time_zone).strftime('%b %d %Y at %l:%M %p %Z')
	end
end
