# Fivv
a twilio- and rails-powered voice conference scheduling and management system

## Configuration
The following environment variables need to be set in order to run Fivv:
  * **TWILIO_SID** - your Twilio account SID
  * **TWILIO_AUTH_TOKEN** - your Twilio auth token
  * **CONFIRMATION_NUMBER** - the administrator's mobile number - requests to confirm new trial accounts will be sent to this number
  * **TWILIO_NUMBER** - the Twilio phone number to use for the app
  * **TWILIO_TWIML_APP_SID** - Twilio app SID for web client
  
The following environment variable is optional:
  * **MAX_PARTICIPANTS** - specify a maximum number of participants for new conferences
  
