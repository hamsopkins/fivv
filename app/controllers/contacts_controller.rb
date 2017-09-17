class ContactsController < ApplicationController
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
			if @contact.save
				redirect_to @contact
			else
				@errors = @contact.errors.full_messages
				render :edit
			end
		else
			redirect_to 'contacts#index'
		end
	end

	def destroy
		redirect_to :root unless helpers.logged_in?
		@contact = Contact.find_by_id(params[:id])
		redirect_to 'contacts#index' unless @contact
		@contact.destroy if @contact.user == helpers.current_user
		redirect_to 'contacts#index'
	end


	private
	def contact_params
		params.require(:contact).permit :name, :phone, :time_zone
	end
end
