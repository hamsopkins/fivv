class SessionsController < ApplicationController
	def new
		redirect_to helpers.current_user if helpers.logged_in?
		@user = User.new unless @user
	end

	def create
		user = User.find_by_phone(session_params[:phone])
		if user
			if Time.now > (user.expiration || Time.now + 604800)
				redirect_to account_expired_url
			else
				if user.authenticate(session_params[:password])
					session[:user_id] = user.id
					redirect_to user_path(user)
				else
					@errors = ["Authentication failed"]
					render :new
				end
			end
		else
			@errors = ["Authentication failed"]
			render :new
		end
	end

	def account_expired
	end

	def destroy
		session.delete(:user_id)
		redirect_to :root
	end

	def forgot_password
		redirect_to :root if helpers.logged_in?
	end

	def generate_token
		redirect_to :root if helpers.logged_in?
		@user = User.find_by_phone(params['token']['phone'])
		if @user
			RecoveryToken.where("user_id = ?", @user.id).destroy_all
			token = RecoveryToken.new(user: @user, token: rand.to_s[2..7])
			if token.save
				client = Twilio::REST::Client.new ENV["TWILIO_SID"], ENV["TWILIO_AUTH_TOKEN"]
				client.messages.create(
					from: ENV["TWILIO_NUMBER"],
					to: "+1#{@user.phone}",
					body: "Your Fivv recovery token: #{token.token}"
				)
				redirect_to reset_password_form_path_url
			else
				@errors = ["Token could not be generated."]
				render :forgot_password
			end
		else
			@errors = ["User not found."]
			render :forgot_password
		end
	end

	def reset_password_form
		redirect_to :root if helpers.logged_in?
	end

	def reset_password
		redirect_to :root if helpers.logged_in?
		@user = User.find_by_phone(params['token']['phone'])
		if @user
			token = RecoveryToken.where("user_id = ? and token = ?", @user.id, params['token']['token']).first
			if token
				if token.created_at > Time.now - 600
					if params['token']['password'].length > 0
						@user.assign_attributes(password: params['token']['password'], password_confirmation: params['token']['password_confirmation'])
						if @user.save
							token.destroy
							session[:user_id] = @user.id
							redirect_to @user
						else
							@errors = @user.errors.full_messages
							render :reset_password_form
						end
					else
						@errors = ["New password cannot be empty."]
						render :reset_password_form
					end
				else
					token.destroy
					@errors = ["Invalid token."]
					render :reset_password_form
				end
			else
				@errors = ["Invalid token."]
				render :reset_password_form
			end
		else
			@errors = ["User not found."]
			render :reset_password_form
		end
	end

	private
	def session_params
		params.require(:session).permit :phone, :password
	end
end
