var dynect = require('./dynect_api.js');
var AWS = require('aws-sdk');

var debug = true;

exports.cloudwatch_alarm_sns_handler = function(event, context) {
	debug_log(JSON.stringify(event, null, 2));

	event.Records.forEach(function(record) {
		var payload = record.Sns.Message;
		debug_log('Payload:' + payload);

		// Example of expected alarm JSON:
		//
		// {
		//	"AlarmName": "High Error Count",
		//	"AlarmDescription": "Alerts when ERROR rate exceeds healthy limits",
		//	"AWSAccountId": "XXXX",
		//	"NewStateValue": "ALARM",
		//	"NewStateReason": "Threshold Crossed: 1 datapoint (6.0) was greater than or equal to the threshold (6.0).",
		//	"StateChangeTime": "2015-05-24T21:40:12.882+0000",
		//	"Region": "US-West-2",
		//	"OldStateValue": "OK",
		//	"Trigger": {
		//		"MetricName": "ERRORLogLines",
		//		"Namespace": "SHSAppMetrics",
		//		"Statistic": "AVERAGE",
		//		"Unit": null,
		//		"Dimensions": [
		//		{
		//			"name": "InstanceId",
		//			"value": "i-ff04cb29"
		//		}],
		//		"Period": 60,
		//		"EvaluationPeriods": 1,
		//		"ComparisonOperator": "GreaterThanOrEqualToThreshold",
		//		"Threshold": 6
		//	}
		// }
		var alarm = JSON.parse(payload);

		// Extract the instance status.  ALARM means it's down, OK means it's up.
		var instance_up = alarm.NewStateValue !== "ALARM";

		var instance_id;
		var instance_public_ip_address;

		// Extract the instance ID from the dimension list.
		alarm.Trigger.Dimensions.forEach(function(dimension) {
			if (dimension.name === "InstanceId") {
				instance_id = dimension.value;
			}
		});

		// To modify the DynECT record, we need the public IP address of the instance.
		// Get it from EC2.
		new AWS.EC2().describeInstances({ InstanceIds: [ instance_id ] }, function(error, data) {
			if (error) {
				// EC2 API call failed.
				debug_log(error);

				// Nothing else we can do.  Report the failure to Lambda.
				context.fail(error);
			} else {
				// EC2 API call succeeded.

				// Extract the public IP address from the response.
				instance_public_ip_address = data.Reservations[0].Instances[0].NetworkInterfaces[0].Association.PublicIp;

				debug_log("Instance ID: " + instance_id);
				debug_log("Instance public IP address: " + instance_public_ip_address);

				// Wrap up the params needed to adjust the DynECT record.
				var args = {
					"customer_name": "",
					"user_name": "",
					"password": "",
					"service_label": "",
					"address": instance_public_ip_address,
					"enabled": instance_up
				};

				// Issue the DynECT "disable address" request.
				set_address_enabled(args, function() {
					// DynECT API call succeeded.

					// Finally, if we got alerted because the instance is down, re-boot it.
					// Once the re-boot finishes, we're hoping it will be in an OK state again,
					// and we'll get called to re-enable the DynECT record.
					if (instance_up) {
						// We're done!
						debug_log("No re-boot required.");
						context.succeed();
					} else {
						debug_log("Re-booting instance " + instance_id);
						new AWS.EC2().rebootInstances({ InstanceIds: [ instance_id ] }, function(error, data) {
							if (error) {
								// EC2 API call failed.
								debug_log(error);

								// Nothing else we can do.  Report the failure to Lambda.
								context.fail(error);
							} else {
								// EC2 API call succeeded.

								// We're done!
								context.succeed();
							}
						});
					}
				});
			}
		});
	});
}

set_address_enabled = function(args, callback) {
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

				if (enabled) {
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

					if (callback) {
						callback();
					}
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
