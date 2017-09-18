class SessionsController < ApplicationController
	def new
		redirect_to helpers.current_user if helpers.logged_in?
		@user = User.new unless @user
	end

	def create
		user = User.find_by_phone(session_params[:phone])
		if user
			if Time.now > (user.expiration || Time.now + 604800)
				user.destroy
				redirect_to account_expired_url
			else
				if user.authenticate(session_params[:password])
					session[:user_id] = user.id
					if user.active_user
						redirect_to user_path(user)
					else
						redirect_to success_path_url
					end
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

	private
	def session_params
		params.require(:session).permit :phone, :password
	end
end
