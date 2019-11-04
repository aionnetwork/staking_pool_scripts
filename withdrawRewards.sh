#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# This script can be used to withdraw rewards.
#
# Usage: ./withdrawRewards.sh node_address delegator_private_key pool_identity_address network_name
# -----------------------------------------------------------------------------

POOL_REGISTRY_AMITY_ADDRESS="0xa01b68fa4f947ea4829bebdac148d1f7f8a0be9a8fd5ce33e1696932bef05356"
POOL_REGISTRY_MAINNET_ADDRESS="0xa008e42a76e2e779175c589efdb2a0e742b40d8d421df2b93a8a0b13090c7cc8"
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

function capture_event()
{
	payload={\"jsonrpc\":\"2.0\",\"method\":\"eth_getTransactionReceipt\",\"params\":[\"$1\"],\"id\":1}
	response=`curl -s -X POST -H "Content-Type: application/json" --data "$payload" "$node_address"`
    amount_hex="$(echo "$response" | egrep -oh 'data":"0x'"[[:xdigit:]]+" | egrep -oh "0x[[:xdigit:]]+")"
	echo "Rewards withdrawn = $(( 16#${amount_hex:2} )) nAmps."
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

if [ $# -ne 4 ]
then
    echo "Invalid number of parameters."
    echo "Usage: ./withdrawRewards.sh node_address delegator_private_key pool_identity_address network_name(amity/mainnet)"
    exit 1
fi
node_address="$1"
private_key="$2"
pool_identity_address="$3"
network=$( echo "$4" | tr '[A-Z]' '[a-z]' )
pool_registry_address=

if [[ "$network" = "amity" ]]
then
    pool_registry_address=${POOL_REGISTRY_AMITY_ADDRESS}
elif [[ "$network" = "mainnet" ]]
then
    pool_registry_address=${POOL_REGISTRY_MAINNET_ADDRESS}
else
    echo "Invalid network name. Only amity and mainnet networks are supported."
    exit 1
fi

if [ ${#private_key} == 130 ]
then
    private_key=${private_key::-64}
fi

delegator_address="$(java -cp $TOOLS_JAR cli.KeyExtractor "$private_key")"

get_nonce "$delegator_address"
nonce="$return"
echo "Using nonce $nonce"

echo "Withdrawing rewards..."

# withdraw(Address pool)
callPayload="$(java -cp $TOOLS_JAR cli.ComposeCallPayload "withdrawRewards" "$pool_identity_address")"
receipt=`./rpc.sh --call "$private_key" "$nonce" "$pool_registry_address" "$callPayload" "0" "$node_address"`
require_success $?

echo "Transaction hash: \"$receipt\".  Waiting for transaction to complete..."
wait_for_receipt "$receipt"
echo "Transaction completed"
capture_event "$receipt"

echo "Withdraw complete."
