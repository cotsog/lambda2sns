PROJECT = $(shell basename $(CURDIR))
STACK_NAME ?= $(PROJECT)
AWS_REGION = ap-southeast-1
DEPLOY_S3_PREFIX = lambda2sns

.PHONY: deps clean build test deploy

# https://blog.deleu.dev/leveraging-aws-sqs-retry-mechanism-lambda/

deps:
	go mod tidy

build: deps
	GOOS=linux GOARCH=amd64 go build -o lambda2sns .

test:
	go test ./...

logs:
	sam logs -n alambda_simple -t

destroy:
	aws cloudformation delete-stack \
		--stack-name $(STACK_NAME)

deploy: build
	sam validate --template template.yaml
	sam package --template-file template.yaml --s3-bucket dev-media-unee-t --s3-prefix $(DEPLOY_S3_PREFIX) --output-template-file packaged.yaml
	AWS_PROFILE=uneet-dev sam deploy --template-file ./packaged.yaml --stack-name $(STACK_NAME) --capabilities CAPABILITY_IAM

demo: build
	AWS_PROFILE=uneet-demo sam package --template-file template.yaml --s3-bucket demo-media-unee-t --s3-prefix $(DEPLOY_S3_PREFIX) --output-template-file packaged.yaml
	AWS_PROFILE=uneet-demo sam deploy --template-file ./packaged.yaml --stack-name $(STACK_NAME) --capabilities CAPABILITY_IAM --parameter-overrides DefaultSecurityGroup=sg-6f66d316 PrivateSubnets=subnet-0bdef9ce0d0e2f596,subnet-091e5c7d98cd80c0d,subnet-0fbf1eb8af1ca56e3

lint:
	cfn-lint template.yaml
