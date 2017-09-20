class ConferencesController < ApplicationController
	before_action :destroy_expired_account
	around_action :user_time_zone, only: [:edit, :show, :index, :create, :update]

	def new
		@conference = Conference.new unless @conference
	end

	def create
		redirect_to :root unless helpers.logged_in?
		@conference = Conference.new(conference_params)
		@conference.user = helpers.current_user
		@conference.access_code = rand.to_s[2..7]
		admin_pin = @conference.set_pin
		if @conference.valid?
			@conference.conference_contacts << params['conference']['contacts'].reject {|id| id.length == 0 || Contact.find(id).user != helpers.current_user }.map { |id| ConferenceContact.new(contact_id: id, conference: @conference).set_pin }
			@conference.inform_admin(admin_pin)
		end
		if @conference.save
			redirect_to @conference
		else
			@errors = @conference.errors.full_messages
			render :new
		end

	end

	def edit
		redirect_to :root unless helpers.logged_in?
		@conference = Conference.find_by_id(params[:id])
		redirect_to conferences_path unless @conference
		redirect_to conferences_path unless @conference.user == helpers.current_user
		render :edit
	end

	def update
		redirect_to :root unless helpers.logged_in?
		@conference = Conference.find_by_id(params[:id])
		redirect_to conferences_path unless @conference
		redirect_to conferences_path unless @conference.user == helpers.current_user
		@conference.assign_attributes(conference_params)
		if @conference.valid?
			existing_contact_ids = @conference.conference_contacts.map { |contact| contact.contact.id }
			updated_contact_ids = params['conference']['contacts'].reject {|id| id.length == 0 || Contact.find(id).user != helpers.current_user }.map(&:to_i)
			remaining_contact_ids = existing_contact_ids & updated_contact_ids
			uninvited_contact_ids = existing_contact_ids - remaining_contact_ids
			uninvited_contact_ids.map { |id| ConferenceContact.where("contact_id = ? and conference_id = ?", id, @conference.id) }.flatten.each { |c| c.inform_canceled }
			remaining_contact_ids.map { |id| ConferenceContact.where("contact_id = ? and conference_id = ?", id, @conference.id) }.flatten.each { |c| c.inform_updated_time }
			new_contact_ids = updated_contact_ids - remaining_contact_ids
			@conference.conference_contacts << new_contact_ids.map {|id| ConferenceContact.new(contact_id: id, conference: @conference).set_pin }
		end
		if @conference.save
			redirect_to @conference
		else
			@errors = @conference.errors.full_messages
			render :edit
		end
	end

	def destroy
		redirect_to :root unless helpers.logged_in?
		@conference = Conference.find_by_id(params[:id])
		redirect_to conferences_path unless @conference
		redirect_to conferences_path unless @conference.user == helpers.current_user
		@conference.conference_contacts.each { |contact| contact.inform_canceled }
		@conference.destroy
		redirect_to conferences_path
	end

	def index
		redirect_to :root unless helpers.logged_in?
		@user = helpers.current_user
		@conferences = Conference.where("user_id = ? and end_time > ?", @user.id, Time.now).order(:start_time)
		render :index
	end

	def show
		redirect_to :root unless helpers.logged_in?
		@conference = Conference.find_by_id(params[:id])
		redirect_to :root unless helpers.current_user == @conference.user
		if Time.now > @conference.start_time - 300 && Time.now < @conference.end_time
	  	capability = Twilio::JWT::ClientCapability.new ENV['TWILIO_SID'], ENV['TWILIO_AUTH_TOKEN']
	  	capability.add_scope(Twilio::JWT::ClientCapability::OutgoingClientScope.new(ENV['TWILIO_TWIML_APP_SID'], nil, {'Conference' => @conference.access_code}))
	  	@token = capability.to_jwt
	  end
	end

	private
	def conference_params
		params.require(:conference).permit :name, :start_time, :end_time, :contacts, :moderated
	end

	def user_time_zone
	  Time.use_zone(helpers.current_user.time_zone) { yield }
	end

	def destroy_expired_account
		if helpers.logged_in?
			if Time.now > (helpers.current_user.expiration || Time.now + 604800)
				helpers.current_user.destroy
				session.delete(:user_id)
				redirect_to account_expired_url
			end
		end
	end

end
