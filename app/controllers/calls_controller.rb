class CallsController < ApplicationController
	include Webhookable
	skip_before_action :verify_authenticity_token
	after_action :set_header, except: :token

	def incoming
		response = Twilio::TwiML::Response.new do |r|
			r.Gather(action: '/select_conference', method: 'POST', numDigits: 6, timeout: 10) do |g|
				g.Say "Hello and welcome to Fiv. Please enter your conference code."
			end
			r.Say "I didn't get a response. Goodbye."
		end
		render plain: response.text
	end

	def select_conference
		conference = Conference.find_by_access_code(params['Digits'])
		if conference
			if conference.start_time > Time.now - 600 && Time.now < conference.end_time
				response = Twilio::TwiML::Response.new do |r|
					r.Gather(action: "/authenticate/#{conference.access_code}", method: 'POST', numDigits: 6, timeout: 10) do |g|
						g.Say "Please enter your pin."
					end
					r.Say "I didn't get a response. Goodbye."
				end
			else
				response = Twilio::TwiML::Response.new { |r| r.Say "Conference is over or has not started yet. Goodbye." }
			end
		else
			response = Twilio::TwiML::Response.new { |r| r.Say "Conference not found. Goodbye." }
		end
		render plain: response.text
	end

	def authenticate
		conference = Conference.find_by_access_code(params[:id])
		if conference
			if conference.authenticate(params['Digits'])
				is_admin = true
			else
				is_admin = false
			end
			unless is_admin
				conference_contact = conference.conference_contacts.find { |c| c.authenticate(params['Digits']) }
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
				response = Twilio::TwiML::Response.new do |r|
					r.Dial do |d|
						d.Conference(conference.access_code,
							startConferenceOnEnter: start_conf,
							maxParticipants: (conference.contacts.count + 1),
							recordingStatusCallback: '/recording_callback',
							statusCallback: '/callback',
							statusCallbackEvent: 'start end join leave'
						)
					end
				end
			else
				response = Twilio::TwiML::Response.new { |r| r.Say "Invalid pin. Goodbye." }		
			end
		else
			response = Twilio::TwiML::Response.new { |r| r.Say "Something weird happened. Goodbye." }
		end
		render plain: response.text
	end

	def incoming_sms
		if params['From'] == ENV["CONFIRMATION_NUMBER"] && params['Body'].downcase.start_with?("approve")
			client = Twilio::REST::Client.new ENV["TWILIO_SID"], ENV["TWILIO_AUTH_TOKEN"]
			user_id = params['Body'].split(' ').last.to_i
			user = User.find(user_id)
			if user
				user.active_user = true
	# add row to users table datetime for account expiry?
	# then disable login after expiry (say one week?)
				if user.save
					client.messages.create(
						from: ENV["TWILIO_NUMBER"],
						to: ENV["CONFIRMATION_NUMBER"],
						body: "User #{user.name}#{' from ' + user.company if user.company.length > 0} has been approved."
					)
					client.messages.create(
						from: ENV["TWILIO_NUMBER"],
						to: "+1#{user.phone}",
	# if account time limits are added, make sure the confirmation text mentions this
						body: "Hello from Fivv! Your account is now active. Go ahead - log in and try it out!"
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
