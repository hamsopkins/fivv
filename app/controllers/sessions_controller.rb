class SessionsController < ApplicationController
	def new
		user = User.new unless user
	end

	def create
		user = User.find_by_phone(session_params[:phone])
		if user
			if user.expiration
				if Time.now > user.expiration
					user.destroy
					redirect_to 'sessions#account_expired'
				end
			end
			if user.authenticate(session_params[:password])
				session[:user_id] = user.id
				user.active_user ? redirect_to 'users#show' : redirect_to 'users#success'
			else
				@errors = ["Authentication failed"]
				render :new
			end
		else
			@errors = ["Authentication failed"]
		end
	end

	def destroy
		session.delete(:user_id)
		redirect_to :root
	end

	def account_expired
		render :account_expired
	end

	private
	def session_params
		params.require(:session).permit :phone, :password
	end
end
