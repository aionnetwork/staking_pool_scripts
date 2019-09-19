#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# This script can be used to transfer stake from one pool to another pool.
#
# Usage: ./transferDelegation.sh node_address delegator_private_key delegator_address from_pool_identity_address to_pool_identity_address amount fee
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

function capture_event()
{
	payload={"jsonrpc":"2.0","method":"eth_getTransactionReceipt","params":["$1"],"id":1}
	response=`curl -s -X POST -H "Content-Type: application/json" --data "$payload" "$node_address"`
	# ADSDelegationTransferred topic
	if [[ "$response" =~ (\"0x41445344656c65676174696f6e5472616e736665727265640000000000000000\".+\"id) ]];
	then
		result=${BASH_REMATCH[0]:70}
		echo "Transfer Id = $(( 16#${result:2:64}))"
	else
		echo "Error! Could not find event log for ADSDelegationTransferred."
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
			echo "Error! Transaction failed."
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

if [ $# -ne 7 ]
then
    echo "Invalid number of parameters."
    echo "Usage: ./transferDelegation.sh node_address(ip:port) delegator_private_key delegator_address from_pool_identity_address to_pool_identity_address amount fee"
    exit 1
fi
node_address="$1"
private_key="$2"
delegator_address="$3"
from_pool_address="$4"
to_pool_address="$5"
amount="$6"
fee="$7"

get_nonce "$delegator_address"
nonce="$return"
echo "Using nonce $nonce"

echo "Transferring $amount nAmps from $from_pool_address $to_pool_address..."

# transferDelegation(Address fromPool, Address toPool, BigInteger amount, BigInteger fee)
callPayload="$(java -cp $TOOLS_JAR cli.ComposeCallPayload "transferDelegation" "$from_pool_address" "$to_pool_address" "$amount" "$fee")"
receipt=`./rpc.sh --call "$private_key" "$nonce" "$POOL_REGISTRY_ADDRESS" "$callPayload" "0"`
require_success $?

echo "Transaction hash: \"$receipt\".  Waiting for transaction to complete..."
wait_for_receipt "$receipt"
echo "Transaction completed"
capture_event "$receipt"

echo "Retrieving the total stake for $delegator_address in from pool..."
# getStake(Address pool, Address staker)
callPayload="$(java -cp $TOOLS_JAR cli.ComposeCallPayload "getStake" "$from_pool_address" "$delegator_address")"
# This result in a BigInteger:  0x23 (byte), length (byte), value (big-endian length bytes)
echo_state "$POOL_REGISTRY_ADDRESS" "$callPayload"
echo "Transfer complete."
