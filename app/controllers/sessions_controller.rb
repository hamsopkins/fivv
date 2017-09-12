class SessionsController < ApplicationController
	def new
		user = User.new unless user
	end

	def create
		user = User.find_by_phone(session_params[:phone])
		if user 
			if user.authenticate(session_params[:password])
				session[:user_id] = user.id
				redirect_to :root
			else
				errors = ["Authentication failed"]
				render :new
			end
		else
			errors = ["Authentication failed"]
		end
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
