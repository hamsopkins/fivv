# Fivv
A twilio- and rails-powered voice conference scheduling and management system

Users can create an address book of their contacts, specifying each contact's name, mobile number, and time zone. Users can then schedule voice conferences and invite contacts from their address book to participate. Users can specify whether a conference is moderated, meaning that the conference will not begin (other participants will be put on hold) until the conference organizer joins. Participants can join the conference from five minutes before the scheduled start time until the scheduled end time.

When a conference is first scheduled, the organizer and all participants receive a text message with the conference details (in the participant's local time zone) and their login credentials, which are hashed and stored securely in a PostgreSQL database. Need to change the conference time? No problem - your participants will automatically be sent a text message with the updated details. Need to uninvite someone? Also not a problem - their login credentials will be revoked and they will receive a text message informing them that the conference was canceled.

For added security, Fivv will not allow the same login credentials to be used simultaneously to join a conference, but don't worry if a user gets disconnected or has to hang up for a few minutes - Fivv will detect that and allow them to rejoin the conference.

Fivv is currently configured to accept only North American phone numbers, but can easily be reconfigured to work with phone numbers in any country supported by Twilio.

[A trial demo](http://fivv.samhopkins.tech/) is available to test out. Trial accounts remain active for one week after admin approval.

## Configuration
The following environment variables need to be set in order to run Fivv:
  * **TWILIO_SID** - your Twilio account SID
  * **TWILIO_AUTH_TOKEN** - your Twilio auth token
  * **CONFIRMATION_NUMBER** - the administrator's mobile number - requests to confirm new trial accounts will be sent to this number
  * **TWILIO_NUMBER** - the Twilio phone number to use for the app
  * **TWILIO_TWIML_APP_SID** - Twilio app SID for web client
  
The following environment variable is optional:
  * **MAX_PARTICIPANTS** - specify a maximum number of participants for new conferences
  
