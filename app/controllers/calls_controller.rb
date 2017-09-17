class CallsController < ApplicationController
	include Webhookable
	skip_before_action :verify_authenticity_token
	after_action :set_header, except: :token

	def incoming
		response = Twilio::TwiML::VoiceResponse.new do |r|
			r.gather(action: '/select_conference', method: 'POST', num_digits: 6, timeout: 10) do |g|
				g.say "Hello and welcome to Fiv. Please enter your conference code."
			end
			r.say "I didn't get a response. Goodbye."
		end
		render plain: response.to_s
	end

	def select_conference
		conference = Conference.find_by_access_code(params['Digits'])
		if conference
			if (Time.now > conference.start_time - 600) && (Time.now < conference.end_time)
				response = Twilio::TwiML::VoiceResponse.new do |r|
					r.gather(action: "/authenticate/#{conference.access_code}", method: 'POST', num_digits: 6, timeout: 10) do |g|
						g.say "Please enter your pin."
					end
					r.say "I didn't get a response. Goodbye."
				end
			else
				response = Twilio::TwiML::VoiceResponse.new { |r| r.say "Conference is over or has not started yet. Goodbye." }
			end
		else
			response = Twilio::TwiML::VoiceResponse.new { |r| r.say "Conference not found. Goodbye." }
		end
		render plain: response.to_s
	end

	def authenticate
		conference = Conference.find_by_access_code(params[:id])
		if conference
			if conference.authenticate(params['Digits']) && conference.admin_call_sid == nil
				is_admin = true
			else
				is_admin = false
			end
			if is_admin
				puts "ADMIN HERE"
				conference.admin_call_sid = params['CallSid']
				conference.save(validate: false)
			else
				puts "NOT ADMIN HERE"
				conference_contact = conference.conference_contacts.find { |c| c.authenticate(params['Digits']) && c.call_sid == nil }
# IMPORTANT SECURITY NOTE
# need to add security so same user can't join conference
# simultaneously. to accomplish this, need to add row to conference_contact
# and conference table (the latter table for admin) to specify if that user
# is active in the conference. will need to add callback method
# in a controller to mark user inactive when leaving conference
# in case user is disconnected and needs to reconnect
# or simply add a callback to remove call_sid when a user disconnects
# but in this instance security for admin user still needs to be addressed
				conference_contact.call_sid = params['CallSid']
				conference_contact.save
			end
			if is_admin || conference_contact
				if conference.moderated && !is_admin
					start_conf = false
				else
					start_conf = true
				end			
				response = Twilio::TwiML::VoiceResponse.new do |r|
					r.dial do |d|
						d.conference(conference.access_code,
							start_conference_on_enter: start_conf,
							max_participants: (conference.contacts.count + 1),
							status_callback: '/callback',
							status_callback_event: 'leave'
						)
					end
				end
			else
				response = Twilio::TwiML::VoiceResponse.new { |r| r.say "Invalid pin. Goodbye." }		
			end
		else
			response = Twilio::TwiML::VoiceResponse.new { |r| r.say "Something weird happened. Goodbye." }
		end
		render plain: response.to_s
	end

	def callback
		puts "\n\nCALLBACK"
		puts params
		puts "\n\n"
		conference = Conference.find_by_access_code(params['FriendlyName'])
		if conference.admin_call_sid == params['CallSid']
			conference.admin_call_sid = nil
			conference.save(validate: false)
		else
			participant = ConferenceContact.find_by_call_sid(params['CallSid'])
			participant.call_sid = nil
			participant.save
		end
		render body: nil, status: 204
	# there will be a callback when a conference first starts that will contain its SID - this will need to be saved to the DB to link with later recordings when they are made available by twilio
	# code in this method will need to deal with any callbacks when users join or leave a conference
	# this will need to find the conf_contact by callsid and log appropriately in the conf_actions table
	# when conference ends, delete access_code from conference

	end

	def incoming_sms
		if params['From'] == ENV["CONFIRMATION_NUMBER"] && params['Body'].downcase.start_with?("approve")
			client = Twilio::REST::Client.new ENV["TWILIO_SID"], ENV["TWILIO_AUTH_TOKEN"]
			user_id = params['Body'].split(' ').last.to_i
			user = User.find(user_id)
			if user
				user.active_user = true
				user.expiration = Time.now + 604800
				if user.save
					client.messages.create(
						from: ENV["TWILIO_NUMBER"],
						to: ENV["CONFIRMATION_NUMBER"],
						body: "User #{user.name}#{' from ' + user.company if user.company.length > 0} has been approved."
					)
					client.messages.create(
						from: ENV["TWILIO_NUMBER"],
						to: "+1#{user.phone}",
						body: "Hello from Fivv! Your trial account is now active. Go ahead - log in and try it out! Your account will expire in seven days."
					)
				else
					client.messages.create(
						from: ENV["TWILIO_NUMBER"],
						to: ENV["CONFIRMATION_NUMBER"],
						body: "ERROR! User #{user.name}#{' from ' + user.company if user.company.length > 0} can't be approved."
					)
				end
			else
				client.messages.create(
					from: ENV["TWILIO_NUMBER"],
					to: ENV["CONFIRMATION_NUMBER"],
					body: "ERROR! User not found."
				)
			end
		end
	end
end
