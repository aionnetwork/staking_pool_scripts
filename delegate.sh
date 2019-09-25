#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# This script can be used to delegate to a pool.
#
# Usage: ./delegate.sh node_address delegator_private_key pool_identity_address amount
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

	payload={"jsonrpc":"2.0","method":"eth_call","params":[{"to":"$address","data":"$data"}],"id":1}
	response=`curl -s -X POST -H "Content-Type: application/json" --data "$payload" "$node_address"`
	encoded_stake="$(echo "$response" | egrep -oh 'result":"0x'"[[:xdigit:]]+" | egrep -oh "0x[[:xdigit:]]+")"
	stake="$(java -cp $TOOLS_JAR cli.DecodeReturnResult "BigInteger" "$encoded_stake")"
	echo "Current stake = $stake"
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

function get_nonce(){
        address="$1"
        payload={"jsonrpc":"2.0","method":"eth_getTransactionCount","params":["$address","latest"],"id":1}
        response=`curl -s -X POST -H "Content-Type: application/json" --data "$payload" "$node_address"`
        nonce_hex="$(echo "$response" | egrep -oh 'result":"0x'"[[:xdigit:]]+" | egrep -oh "0x[[:xdigit:]]+")"
        return=$(( 16#${nonce_hex:2} ))
}

if [ $# -ne 4 ]
then
    echo "Invalid number of parameters."
    echo "Usage: ./delegate.sh node_address(ip:port) delegator_private_key pool_identity_address amount"
    exit 1
fi
node_address="$1"
private_key="$2"
pool_identity_address="$3"
amount="$4"

if [ ${#private_key} == 130 ]
then
    private_key=${private_key::-64}
    echo "$private_key"
fi

delegator_address="$(java -cp $TOOLS_JAR cli.KeyExtractor "$private_key")"

get_nonce "$delegator_address"
nonce="$return"
echo "Using nonce $nonce"

echo "Delegating $amount nAmps to $pool_identity_address..."

# delegate(Address pool)
callPayload="$(java -cp $TOOLS_JAR cli.ComposeCallPayload "delegate" "$pool_identity_address")"
receipt=`./rpc.sh --call "$private_key" "$nonce" "$POOL_REGISTRY_ADDRESS" "$callPayload" "$amount"`
require_success $?

echo "Transaction hash: \"$receipt\".  Waiting for transaction to complete..."
wait_for_receipt "$receipt"
echo "Transaction completed"

echo "Retrieving the total stake for $delegator_address..."
# getStake(Address pool, Address staker)
callPayload="$(java -cp $TOOLS_JAR cli.ComposeCallPayload "getStake" "$pool_identity_address" "$delegator_address")"
# This result in a BigInteger:  0x23 (byte), length (byte), value (big-endian length bytes)
echo_state "$POOL_REGISTRY_ADDRESS" "$callPayload"
echo "Delegation complete."