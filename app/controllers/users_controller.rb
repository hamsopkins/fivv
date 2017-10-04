class UsersController < ApplicationController
	def new
		redirect_to :root if session[:user_id]
	end

	def create
		user = User.new(user_params) unless user
		user.phone = user.phone.scan(/\d/).join
		user.expiration = Time.now + 172800
		if user.save
			client = Twilio::REST::Client.new ENV["TWILIO_SID"], ENV["TWILIO_AUTH_TOKEN"]
			client.messages.create(
				from: ENV["TWILIO_NUMBER"],
				to: ENV["CONFIRMATION_NUMBER"],
				body: "New Fivv user: #{user.name}#{' from ' + user.company if user.company.length > 0}."
			)
			session[:user_id] = user.id
			redirect_to success_path_url
		else
			@errors = user.errors.full_messages
			render :new
		end
	end

	def edit
		redirect_to :root unless helpers.logged_in?
		@user = helpers.current_user
	end

	def update
		redirect_to :root unless helpers.logged_in?
		@user = helpers.current_user
		if @user.authenticate(params['user']['old_password']) && Time.now < @user.expiration
			@user.assign_attributes(update_user_params)
			if @user.save
				redirect_to @user
			else
				@errors = @user.errors.full_messages
				render :edit
			end
		else
			@errors = ["Your current password is required to update account settings"]
			render :edit
		end
	end

	def success
		redirect_to :root unless helpers.logged_in?
		@user = User.find(session[:user_id])
		if Time.now > @user.expiration
			session.delete(:user_id) 
			redirect_to account_expired_url
		else
			render :success
		end
	end

	def show
		redirect_to :root unless helpers.logged_in?
		@user = User.find(session[:user_id])
		@current_conferences = @user.conferences.where("? < start_time and end_time > ?", Time.now - 300, Time.now)
		if Time.now > (@user.expiration || Time.now + 604800)
			session.delete(:user_id)
			redirect_to account_expired_url
		end
	end

	private
	def user_params
		params.require(:user).permit :name, :phone, :company, :password, :password_confirmation, :time_zone
	end

	def update_user_params
		params.require(:user).permit :name, :company, :password, :password_confirmation, :time_zone
	end
end
