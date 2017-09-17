class ConferencesController < ApplicationController
	around_action :user_time_zone, only: [:edit, :show, :index, :create]

	def new
		@conference = Conference.new unless @conference
	end

	def create
		redirect_to :root unless helpers.logged_in?
		@conference = Conference.new(conference_params)
		@conference.user = helpers.current_user
		@conference.access_code = rand.to_s[2..7]
		admin_pin = @conference.set_pin
		puts "\n\nNEW CONFERENCE"
		puts "ADMIN PIN: #{@admin_pin}\n\n"
		# @conference.save
		if @conference.save
			@conference.conference_contacts << params['conference']['contacts'].reject {|id| id.length == 0 || ConferenceContact.find(id).user != helpers.current_user }.map { |id| ConferenceContact.new(contact_id: id, conference: @conference).set_pin }
			@conference.inform_admin(admin_pin)
			redirect_to conference_url(@conference)
		else
			@errors = @conference.errors.full_messages
			render :new
		end

	end

	def edit
		redirect_to :root unless helpers.logged_in?
		@conference = Conference.find_by_id(params[:id])
		redirect_to 'conferences#index' unless @conference
		redirect_to 'conferences#index' unless @conference.user == helpers.current_user
		render :edit
	end

	def update
		redirect_to :root unless helpers.logged_in?
		@conference = Conference.find_by_id(params[:id])
		redirect_to 'conferences#index' unless @conference
		redirect_to 'conferences#index' unless @conference.user == helpers.current_user
		@conference.assign_attributes(conference_params)
		existing_contact_ids = @conference.conference_contacts.map { |contact| contact.id }
		updated_contact_ids = params['conference']['contacts'].reject {|id| id.length == 0 || ConferenceContact.find(id).user != helpers.current_user }
		remaining_contact_ids = existing_contact_ids & updated_contact_ids
		uninvited_contact_ids = existing_contact_ids - remaining_contact_ids
		uninvited_contact_ids.map { |id| ConferenceContact.find(id) }.each do |c|
			c.inform_canceled
			c.destroy
		end
		new_contact_ids = updated_contact_ids - remaining_contact_ids
		@conference.conference_contacts << new_contact_ids.map {|id| ConferenceContact.new(contact_id: id, conference: @conference).set_pin }
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
		redirect_to 'conferences#index' unless @conference
		redirect_to 'conferences#index' unless @conference.user == helpers.current_user
		@conference.conference_contacts.each { |contact| contact.inform_canceled }
		@conference.destroy
		redirect_to 'conferences#index'
	end

	def index
		redirect_to :root unless helpers.logged_in?
		@user = helpers.current_user
		@conferences = Conference.where("user_id = ? and start_time > ?", @user.id, (Time.now - 7200)).order(:start_time)
		render :index
	end

	def show
		redirect_to :root unless helpers.logged_in?
		@conference = Conference.find_by_id(params[:id])
		redirect_to :root unless helpers.current_user == @conference.user
		@identity = helpers.current_user.name
  	capability = Twilio::Util::Capability.new ENV['TWILIO_SID'], ENV['TWILIO_AUTH_TOKEN']
  	capability.allow_client_outgoing(ENV['TWILIO_TWIML_APP_SID'], {'Conference' => @conference.access_code})
  	@token = capability.generate
  	render :show, layout: false
	end

	private
	def conference_params
		params.require(:conference).permit :name, :start_time, :end_time, :contacts, :moderated
	end

	def user_time_zone
	  Time.use_zone(helpers.current_user.time_zone) { yield }
	end

end
