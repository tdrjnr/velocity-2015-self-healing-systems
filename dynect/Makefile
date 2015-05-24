Lambda.zip: dynect_api.js enable_td_address_lambda.js
	zip Lambda dynect_api.js enable_td_address_lambda.js

lambda: Lambda.zip

all: lambda

clean:
	rm Lambda.zip

publish: all
ifndef LAMBDA_PROFILE
	echo LAMBDA_PROFILE must be set to valid AWS CLI profile name.
	exit 1
endif
ifndef LAMBDA_FUNCTION
	echo LAMBDA_FUNCTION must be set to valid AWS Lambda function name.
	exit 1
endif
	aws --profile $(LAMBDA_PROFILE) lambda update-function-code --function-name $(LAMBDA_FUNCTION) --zip-file fileb://Lambda.zip
