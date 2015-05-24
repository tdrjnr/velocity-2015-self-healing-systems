lambda: Lambda.zip

Lambda.zip: dynect_api.js enable_td_address_lambda.js
	zip Lambda dynect_api.js enable_td_address_lambda.js

clean:
	rm Lambda.zip

all: lambda
