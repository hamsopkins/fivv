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


end
