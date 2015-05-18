#!/usr/bin/env node

var dynect = require('./dynect_api.js');

var argv = require('optimist')
	.usage("Usage: $0 --customer [DynECT customer name] --user [DynECT user] --password [DynECT password] --address [IP address to modify] --enabled [true or false]")
	.demand(["customer", "user", "password", "service", "record", "enabled"])
	.boolean("debug")
	.argv;

var customer_name = argv.customer;
var user_name = argv.user;
var password = argv.password;
var service_label = argv.service;
var address = argv.record;
var enabled = argv.enabled;
var debug = argv.debug;

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

			dynect.update_dsf_record(token, service_id, record_id, updated_record);
		});
	});
});

function debug_log(s) {
	if (debug) {
		console.log("[DEBUG] " + s);
	}
}
