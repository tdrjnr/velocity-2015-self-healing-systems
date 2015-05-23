var dynect = require('./dynect_api.js');

var debug = true;

exports.kinesis_handler = function(event, context) {
	debug_log(JSON.stringify(event, null, 2));

	event.Records.forEach(function(record) {
		// Kinesis data is base64 encoded so decode here
		var payload = new Buffer(record.kinesis.data, 'base64').toString('ascii');
		debug_log('Decoded payload:' + payload);

		var args = JSON.parse(payload);

		set_address_enabled(args, context);
	});
}

set_address_enabled = function(args, context) {
	var customer_name = args.customer_name;
	var user_name = args.user_name;
	var password = args.password;
	var service_label = args.service_label;
	var address = args.address;
	var enabled = args.enabled;

	debug_log("Customer name: " + customer_name);
	debug_log("User name: " + user_name);
	debug_log("Password: " + password);
	debug_log("Service: " + service_label);
	debug_log("Address: " + address);
	debug_log("Enabled: " + enabled);

	dynect.login(customer_name, user_name, password, function(token) {
		debug_log("Token: " + token);

		dynect.get_dsf_services_by_label(token, service_label, function(dsf_services) {
			var service_id = dsf_services[0].service_id;
			debug_log("Service ID: " + service_id);

			dynect.get_dsf_records_by_address(token, service_id, address, function(dsf_records) {
				var record_id = dsf_records[0].dsf_record_id;
				debug_log("Record ID: " + record_id);

				var updated_record;

				if (enabled === "true") {
					updated_record = {
						"automation": "auto",
						"eligible": "true"
					};
				} else {
					updated_record = {
						"automation": "manual",
						"eligible": "false"
					};
				}

				dynect.update_dsf_record(token, service_id, record_id, updated_record, function(dsf_record) {
					debug_log("Success!");
					context.succeeded();
				});
			});
		});
	});
}

function debug_log(s) {
	if (debug) {
		console.log("[DEBUG] " + s);
	}
}
