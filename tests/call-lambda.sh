#!/bin/bash

if ! test -f "$1"
then
	echo Missing JSON payload
	exit 1
fi

json=$1

acc() {
	case $1 in
		dev)  echo 812644853088
		;;
		demo) echo 915001051872
		;;
		prod) echo 192458993663
		;;
	esac
}

domain() {
	case $1 in
		prod) echo auroradb.unee-t.com
		;;
		*) echo auroradb.$1.unee-t.com
		;;
	esac
}


for STAGE in dev # prod
do

echo $STAGE

ssm() {
	aws --profile uneet-$STAGE ssm get-parameters --names $1 --with-decryption --query Parameters[0].Value --output text
}

echo "CALL mysql.lambda_async( 'arn:aws:lambda:ap-southeast-1:$(acc $STAGE):function:alambda_simple', '$(jq -c . $json | phony --max 1)' );" |
mysql -h $(domain $STAGE) -P 3306 -u $(ssm LAMBDA_INVOKER_USERNAME) --password=$(ssm LAMBDA_INVOKER_PASSWORD)
done
