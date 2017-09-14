class UsersController < ApplicationController
	def new
		redirect_to :root if session[:user_id]
	end

	def create
		user = User.new(user_params) unless user
		if user.save
			client = Twilio::REST::Client.new ENV["TWILIO_SID"], ENV["TWILIO_AUTH_TOKEN"]
			client.messages.create(
				from: ENV["TWILIO_NUMBER"],
				to: ENV["CONFIRMATION_NUMBER"],
				body: "Fivv user request. #{user.name}#{' from ' + user.company if user.company} wants to create an account. Reply APPROVE #{user.id} to approve."
			)
			session[:user_id] = user.id
			redirect_to 'users#success'
		else
			@errors = user.errors.full_messages
			render :new
		end
	end

	def success
		redirect_to :root unless helpers.logged_in?
		user = User.find(session[:user_id])
		redirect_to 'users#show' if user.active_user
		render :success
	end

	private
	def user_params
		params.require(:user).permit :name, :phone, :company, :password, :password_confirmation, :time_zone
	end

end
