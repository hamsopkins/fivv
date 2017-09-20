Twilio.Device.setup(token);

Twilio.Device.ready(function (device) {
  log('Ready to connect!');
  document.getElementById('call-controls').style.display = 'block';
});

Twilio.Device.error(function (error) {
  log('Twilio.Device Error: ' + error.message);
});

Twilio.Device.connect(function (conn) {
  log('Connected to conference!');
  document.getElementById('button-call').style.display = 'none';
  document.getElementById('button-hangup').style.display = 'inline';
});

Twilio.Device.disconnect(function (conn) {
  log('Left conference.');
  document.getElementById('button-call').style.display = 'inline';
  document.getElementById('button-hangup').style.display = 'none';
});

document.getElementById('button-call').onclick = function () {
	console.log('Connecting to conference');
	Twilio.Device.connect();
};

// Bind button to hangup call
document.getElementById('button-hangup').onclick = function () {
	log('Leaving conference...');
	Twilio.Device.disconnectAll();
};

// Activity log
function log(message) {
  var logDiv = document.getElementById('log');
  logDiv.innerHTML += '<p>&gt;&nbsp;' + message + '</p>';
  logDiv.scrollTop = logDiv.scrollHeight;
}
