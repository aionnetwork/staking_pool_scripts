#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# This script can be used to undelegate stake from pool.
#
# Usage: ./undelegate.sh node_address delegator_private_key pool_identity_address amount fee
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

function echo_state()
{
	address="$1"
	data="$2"
	expected="$3"

	payload={\"jsonrpc\":\"2.0\",\"method\":\"eth_call\",\"params\":[{\"to\":\"$address\",\"data\":\"$data\"}],\"id\":1}
	response=`curl -s -X POST -H "Content-Type: application/json" --data "$payload" "$node_address"`
	encoded_stake="$(echo "$response" | egrep -oh 'result":"0x'"[[:xdigit:]]+" | egrep -oh "0x[[:xdigit:]]+")"
	stake="$(java -cp $TOOLS_JAR cli.DecodeReturnResult "BigInteger" "$encoded_stake")"
	echo "Current stake = $stake"
}

function capture_event()
{
	payload={\"jsonrpc\":\"2.0\",\"method\":\"eth_getTransactionReceipt\",\"params\":[\"$1\"],\"id\":1}
	response=`curl -s -X POST -H "Content-Type: application/json" --data "$payload" "$node_address"`
	# ADSUndelegated topic
	if [[ "$response" =~ (\"0x414453556e64656c656761746564000000000000000000000000000000000000\".+\"id) ]];
	then
		result=${BASH_REMATCH[0]:70}
		echo "Undelegate Id = $(( 16#${result:2:64}))"
	else
		echo "Error! Could not find event log for ADSUndelegated."
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

if [ $# -ne 5 ]
then
    echo "Invalid number of parameters."
    echo "Usage: ./undelegate.sh node_address(ip:port) delegator_private_key pool_identity_address amount fee"
    exit 1
fi
node_address="$1"
private_key="$2"
pool_identity_address="$3"
amount="$4"
fee="$5"

if [ ${#private_key} == 130 ]
then
    private_key=${private_key::-64}
    echo "$private_key"
fi

delegator_address="$(java -cp $TOOLS_JAR cli.KeyExtractor "$private_key")"

get_nonce "$delegator_address"
nonce="$return"
echo "Using nonce $nonce"

echo "Undelegating $amount nAmps from $pool_identity_address..."

# undelegate(Address pool, BigInteger amount, BigInteger fee)
callPayload="$(java -cp $TOOLS_JAR cli.ComposeCallPayload "undelegate" "$pool_identity_address" "$amount" "$fee")"
receipt=`./rpc.sh --call "$private_key" "$nonce" "$POOL_REGISTRY_ADDRESS" "$callPayload" "0" "$node_address"`
require_success $?

echo "Transaction hash: \"$receipt\".  Waiting for transaction to complete..."
wait_for_receipt "$receipt"
echo "Transaction completed"
capture_event "$receipt"

echo "Retrieving the total stake for $delegator_address..."
# getStake(Address pool, Address staker)
callPayload="$(java -cp $TOOLS_JAR cli.ComposeCallPayload "getStake" "$pool_identity_address" "$delegator_address")"
# This result in a BigInteger:  0x23 (byte), length (byte), value (big-endian length bytes)
echo_state "$POOL_REGISTRY_ADDRESS" "$callPayload"
echo "Undelegation complete."
