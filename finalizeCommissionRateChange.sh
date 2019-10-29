#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# This script can be used to finalize a commission rate change request.
#
# Usage: ./finalizeCommissionRateChange.sh node_address(ip:port) pool_private_key request_Id
# -----------------------------------------------------------------------------

POOL_REGISTRY_ADDRESS="0xa01b68fa4f947ea4829bebdac148d1f7f8a0be9a8fd5ce33e1696932bef05356"
TOOLS_JAR=Tools.jar
return=0

function require_success()
{
	if [ $1 -ne 0 ]
	then
		echo "Failed"
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
		`./rpc.sh --check-receipt-status "$receipt" "$node_address"`
		result=$?
		if [ "2" == "$result" ]
		then
			echo "Error! Transaction failed."
			exit 1
		fi
	done
}

function get_nonce(){
        address="$1"
        payload={\"jsonrpc\":\"2.0\",\"method\":\"eth_getTransactionCount\",\"params\":[\"$address\",\"latest\"],\"id\":1}
        response=`curl -s -X POST -H "Content-Type: application/json" --data "$payload" "$node_address"`
        nonce_hex="$(echo "$response" | egrep -oh 'result":"0x'"[[:xdigit:]]+" | egrep -oh "0x[[:xdigit:]]+")"
        return=$(( 16#${nonce_hex:2} ))
}

if [ $# -ne 3 ]
then
    echo "Invalid number of parameters."
    echo "Usage: ./finalizeCommissionRateChange.sh node_address(ip:port) pool_private_key request_Id"
    exit 1
fi
node_address="$1"
private_key="$2"
request_Id="$3"

if [ ${#private_key} == 130 ]
then
    private_key=${private_key::-64}
fi

pool_address="$(java -cp $TOOLS_JAR cli.KeyExtractor "$private_key")"

get_nonce "$pool_address"
nonce="$return"
echo "Using nonce $nonce"

echo "Finalizing request Id $request_Id..."

# finalizeCommissionRateChange(long id)
callPayload="$(java -cp $TOOLS_JAR cli.ComposeCallPayload "finalizeCommissionRateChange" "$request_Id")"
receipt=`./rpc.sh --call "$private_key" "$nonce" "$POOL_REGISTRY_ADDRESS" "$callPayload" "0" "$node_address"`
require_success $?

echo "Transaction hash: \"$receipt\".  Waiting for transaction to complete..."
wait_for_receipt "$receipt"
echo "Transaction completed."
