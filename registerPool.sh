#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# This script can be used to register a pool and do self bond.
#
# Usage: ./registerPool.sh node_address private_key signing_address commission_rate metadata_url metadata_content_hash value network_name
# -----------------------------------------------------------------------------

POOL_REGISTRY_AMITY_ADDRESS="0xa01b68fa4f947ea4829bebdac148d1f7f8a0be9a8fd5ce33e1696932bef05356"
POOL_REGISTRY_MAINNET_ADDRESS="0xa008e42a76e2e779175c589efdb2a0e742b40d8d421df2b93a8a0b13090c7cc8"

STAKER_REGISTRY_AMITY_ADDRESS="0xa056337bb14e818f3f53e13ab0d93b6539aa570cba91ce65c716058241989be9"
STAKER_REGISTRY_MAINNET_ADDRESS="0xa0733306c2ee0c60224b0e59efeae8eee558c0ca1b39e7e5a14a575124549416"

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

function verify_state()
{
	address="$1"
	data="$2"
	expected="$3"

	payload={\"jsonrpc\":\"2.0\",\"method\":\"eth_call\",\"params\":[{\"to\":\"$address\",\"data\":\"$data\"}],\"id\":1}
	response=`curl -s -X POST -H "Content-Type: application/json" --data "$payload" "$node_address"`
	if [[ ! $response =~ $expected ]]
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
		`./rpc.sh --check-receipt-status "$receipt" "$node_address"`
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
        payload={\"jsonrpc\":\"2.0\",\"method\":\"eth_getTransactionCount\",\"params\":[\"$address\",\"latest\"],\"id\":1}
        response=`curl -s -X POST -H "Content-Type: application/json" --data "$payload" "$node_address"`
        nonce_hex="$(echo "$response" | egrep -oh 'result":"0x'"[[:xdigit:]]+" | egrep -oh "0x[[:xdigit:]]+")"
        return=$(( 16#${nonce_hex:2} ))
}

function get_coinbase(){
    address="$1"
    callPayload="$(java -cp $TOOLS_JAR cli.ComposeCallPayload "getCoinbaseAddress" "$address")"
    data={\"jsonrpc\":\"2.0\",\"method\":\"eth_call\",\"params\":[{\"to\":\"$staker_registry_address\",\"data\":\"$callPayload\"}],\"id\":1}
    response=`curl -s -X POST -H "Content-Type: application/json" --data "$data" "$node_address"`
    if [[ "$response" =~ (\"result\":\"0x[0-9a-f]{66}) ]];
    then
        echo "Coinbase address = "${BASH_REMATCH[0]:14:68}""
    else
        echo "Could not retrieve the coinbase address."
    fi
}

if [ $# -ne 8 ]
then
    echo "Invalid number of parameters."
    echo "Usage: ./registerPool.sh node_address(ip:port) private_key signing_address commission_rate metadata_url metadata_content_hash value network_name(amity/mainnet)"
    exit 1
fi
node_address="$1"
private_key="$2"
signing_address="$3"
commission="$4"
metadata_url="$5"
metadata_content_hash="$6"
amount="$7"
network=$( echo "$8" | tr '[A-Z]' '[a-z]' )
pool_registry_address=
staker_registry_address=

if [[ "$network" = "amity" ]]
then
    pool_registry_address=${POOL_REGISTRY_AMITY_ADDRESS}
    staker_registry_address=${STAKER_REGISTRY_AMITY_ADDRESS}
elif [[ "$network" = "mainnet" ]]
then
    pool_registry_address=${POOL_REGISTRY_MAINNET_ADDRESS}
    staker_registry_address=${STAKER_REGISTRY_MAINNET_ADDRESS}
else
    echo "Invalid network name. Only amity and mainnet networks are supported."
    exit 1
fi

if [ ${#private_key} == 130 ]
then
    private_key=${private_key::-64}
fi

identity_address="$(java -cp $TOOLS_JAR cli.KeyExtractor "$private_key")"

echo "Identity address = $identity_address"
echo "Signing address = $signing_address"
echo "Commission rate = $commission"
echo "Metadata URL = $metadata_url"
echo "Metadata content hash = $metadata_content_hash"

get_nonce "$identity_address"
NONCE="$return"
echo "Using nonce $NONCE"

echo "Sending registration call..."
# registerStaker(Address signingAddress, int commissionRate, byte[] metaDataUrl, byte[] metaDataContentHash)
callPayload="$(java -cp $TOOLS_JAR cli.ComposeCallPayload "registerPool" "$signing_address" "$commission" "$metadata_url" "$metadata_content_hash")"
receipt=`./rpc.sh --call "$private_key" "$NONCE" "$pool_registry_address" "$callPayload" "$amount" "$node_address"`
require_success $?

echo "Transaction hash: \"$receipt\".  Waiting for transaction to complete..."
wait_for_receipt "$receipt"
echo "Transaction completed"

echo "Verifying that pool was registered and is active..."
# getStake(Address pool, Address staker)
callPayload="$(java -cp $TOOLS_JAR cli.ComposeCallPayload "getStake" "$identity_address" "$identity_address")"
amount_hex="$(java -cp $TOOLS_JAR cli.EncodeType "BigInteger" "$amount")"
# This result in a BigInteger:  0x23 (byte), length (byte), value (big-endian length bytes)
verify_state "$pool_registry_address" "$callPayload" "$amount_hex"
echo "Current stake = $amount nAmps"

callPayload="$(java -cp $TOOLS_JAR cli.ComposeCallPayload "isActive" "$identity_address")"
# This result in boolean:  0x02 (byte), value
verify_state "$staker_registry_address" "$callPayload" "0x0201"

get_coinbase "$identity_address"

echo "$identity_address is now active."

echo "Registration complete."
