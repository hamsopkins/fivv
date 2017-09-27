class ContactsController < ApplicationController
	before_action :redirect_expired_account

	def index
		if helpers.logged_in?
			user = helpers.current_user
			@contacts = Contact.where('user_id = ?', user.id).order(:name)
		else
			redirect_to :root
		end
	end

	def show
		redirect_to :root unless helpers.logged_in?
		@contact = Contact.find_by_id(params[:id])
		redirect_to contacts_path unless @contact
		redirect_to :root unless @contact.user == helpers.current_user
	end

	def new
		redirect_to :root unless helpers.logged_in?
		@contact = Contact.new unless @contact
	end

	def create
		redirect_to :root unless helpers.logged_in?
		@contact = Contact.new(contact_params)
		@contact.phone = @contact.phone.scan(/\d/).join
		@contact.user = helpers.current_user
		if @contact.save
			redirect_to contacts_path
		else
			@errors = @contact.errors.full_messages
			render :new
		end
	end

	def edit
		@contact = Contact.find_by_id(params[:id])
		redirect_to :root if @contact.user != helpers.current_user
	end

	def update
		redirect_to :root unless helpers.logged_in?
		@contact = Contact.find_by_id(params[:id])
		if @contact.user == helpers.current_user
			@contact.assign_attributes(contact_params)
			@contact.phone = @contact.phone.scan(/\d/).join
			if @contact.save
				redirect_to @contact
			else
				@errors = @contact.errors.full_messages
				render :edit
			end
		else
			redirect_to contacts_path
		end
	end

	def destroy
		redirect_to :root unless helpers.logged_in?
		@contact = Contact.find_by_id(params[:id])
		redirect_to contacts_path unless @contact
		@contact.destroy if @contact.user == helpers.current_user
		redirect_to contacts_path
	end


	private
	def contact_params
		params.require(:contact).permit :name, :phone, :time_zone
	end

	def redirect_expired_account
		if helpers.logged_in?
			if Time.now > (helpers.current_user.expiration || Time.now + 604800)
				session.delete(:user_id)
				redirect_to account_expired_url
			end
		end
	end
end
