#!/bin/bash

PRIVATE_KEY="0xcc76648ce8798bc18130bc9d637995e5c42a922ebeab78795fac58081b9cf9d4"
EXPECTED_DAPP_ADDRESS="0xa056337bb14e818f3f53e13ab0d93b6539aa570cba91ce65c716058241989be9"
JAR_PATH="registry.jar"

function require_success()
{
	if [ $1 -ne 0 ]
	then
		echo "Failed"
		exit 1
	fi
}

function verify_state()
{
	address="$1"
	data="$2"
	expected="$3"

	payload={"jsonrpc":"2.0","method":"eth_call","params":[{"to":"$address","data":"$data"}],"id":1}
	response=`curl -s -X POST --data "$payload" 127.0.0.1:8545`
	if [ "$expected" != "$response" ]
	then
		echo "Incorrect response from eth_call: \"$response\""
		exit 1
	fi
}

function wait_for_receipt()
{
	receipt="$1"
	result="1"
	while [ "1" == "$result" ]
	do
		echo " waiting..."
		sleep 1
		`./rpc.sh --check-receipt-status "$receipt"`
		result=$?
		if [ "2" == "$result" ]
		then
			echo "Error"
			exit 1
		fi
	done
}


echo "Deploying the registry.jar..."
receipt=`./rpc.sh --deploy "$PRIVATE_KEY" "0" "$JAR_PATH"`
require_success $?

echo "Deployment returned receipt: \"$receipt\".  Waiting for deployment to complete..."
address=""
while [ "" == "$address" ]
do
	echo " waiting..."
	sleep 1
	address=`./rpc.sh --get-receipt-address "$receipt"`
	require_success $?
done
echo "Deployed to address: \"$address\""
if [ "$EXPECTED_DAPP_ADDRESS" != "$address" ]
then
	echo "Address was incorrect:  Expected $EXPECTED_DAPP_ADDRESS"
	exirt 1
fi

echo "Sending registration call..."
receipt=`./rpc.sh --call "$PRIVATE_KEY" "01" "$address" "0x210008726567697374657222a02df9004be3c4a20aeb50c459212412b1d0a58da3e1ac70ba74dde6b4accf4b" "0"`
echo "$receipt"
require_success $?

echo "Transaction returned receipt: \"$receipt\".  Waiting for transaction to complete..."
wait_for_receipt "$receipt"
echo "Transaction completed"

echo "Sending voting call"
receipt=`./rpc.sh --call "$PRIVATE_KEY" "2" "$address" "0x210004766f746522a02df9004be3c4a20aeb50c459212412b1d0a58da3e1ac70ba74dde6b4accf4b" "1000000000"`
echo "$receipt"
require_success $?

echo "Transaction returned receipt: \"$receipt\".  Waiting for transaction to complete..."
wait_for_receipt "$receipt"
echo "Transaction completed"

echo "Verifying that vote was registered..."
verify_state "$address" "0x210007676574566f746522a02df9004be3c4a20aeb50c459212412b1d0a58da3e1ac70ba74dde6b4accf4b" '{"result":"0x06000000003b9aca00","id":1,"jsonrpc":"2.0"}'

echo "BOOTSTRAP COMPLETE"
