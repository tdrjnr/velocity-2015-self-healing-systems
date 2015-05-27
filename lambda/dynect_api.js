var https = require('https');

var debug = false;

module.exports.login = function(customer_name, user_name, password, callback) {
	var requestParams = {
		customer_name: customer_name,
		user_name: user_name,
		password: password
	};

	do_dynect_request(null,
		requestParams,
		"POST",
		"/REST/Session/",
		function(responseParams) {
			var token = responseParams.data.token;
			callback(token);
		});
};

module.exports.get_dsf_services_by_label = function(token, label, callback) {
	do_dynect_request(token,
		null,
		"GET",
		"/REST/DSF/?label=" + encodeURIComponent(label) + "&detail=Y",
		function(responseParams) {
			var dsf_services = responseParams.data;
			callback(dsf_services);
		});
}

module.exports.get_dsf_records_by_address = function(token, service_id, address, callback) {
	do_dynect_request(token,
		null,
		"GET",
		"/REST/DSFRecord/" + encodeURIComponent(service_id) + "/?endpoints=" + encodeURIComponent(address) + "&detail=Y",
		function(responseParams) {
			var dsf_records = responseParams.data;
			callback(dsf_records);
		});
}

module.exports.update_dsf_record = function(token, service_id, record_id, updated_record, callback) {
	do_dynect_request(token,
		updated_record,
		"PUT",
		"/REST/DSFRecord/" + encodeURIComponent(service_id) + "/" + encodeURIComponent(record_id) + "/?publish=Y",
		function(responseParams, err) {
			if (callback) {
				var dsf_record = responseParams == null ? null : responseParams.data;
				callback(dsf_record, err);
			}
		});
};

function do_dynect_request(token, requestParams, method, path, callback) {
	var requestBody = requestParams == null ? "" : JSON.stringify(requestParams);

	if (debug) {
		console.log("[DEBUG] " + method + " " + path);
		console.log("[DEBUG] Sending JSON request: " + requestBody);
	}

	var headers = {
		"Content-Type": "application/json",
		"Content-Length": requestBody.length,
		"Connection": "close"
	};

	if (token) {
		headers["Auth-Token"] = token;
	}

	var options = {
		host: "api2.dynect.net",
		method: method,
		path: path,
		port: 443,
		headers: headers
	};

	var responseBody = "";

	var req = https.request(options, function(response) {
		response.on('data', function (chunk) {
			responseBody += chunk;
		});

		response.on('end', function () {
			if (debug) {
				console.log("[DEBUG] Got JSON response: " + responseBody);
			}

			if (callback) {
				var responseParams = JSON.parse(responseBody);
				callback(responseParams);
			}
		});

		response.on('error', console.log);
	});

	req.on('error', function(e) {
		callback(null, e);
	});

	req.end(requestBody);
}
