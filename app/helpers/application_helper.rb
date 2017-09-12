module ApplicationHelper
	def logged_in?
		cookies.encrypted[:user_id] = nil if session[:user_id] == nil
		session[:user_id] != nil
	end

	def current_user
		logged_in? ? (User.find(session[:user_id])) : nil
	end
end
