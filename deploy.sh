#!/bin/bash
# -----------------------------------------------------------------------------
# This script can be used to deploy StakerRegistry and PoolRegistry contracts.
#
# Usage: ./deploy.sh
# Note: PRIVATE_KEY, NONCE, EXPECTED_STAKER_REGISTRY_ADDRESS should be set before running the script.
# -----------------------------------------------------------------------------

#Private key of the deployer account
PRIVATE_KEY="0xcc76648ce8798bc18130bc9d637995e5c42a922ebeab78795fac58081b9cf9d4"
#Nonce of the deployer account
NONCE=0
EXPECTED_STAKER_REGISTRY_ADDRESS="0xa056337bb14e818f3f53e13ab0d93b6539aa570cba91ce65c716058241989be9"
STAKER_JAR_PATH="stakerRegistry.jar"
POOL_JAR_PATH="poolRegistry.jar"

function require_success()
{
	if [ $1 -ne 0 ]
	then
		echo "Failed"
		exit 1
	fi
}

echo "Deploying the stakerRegistry.jar..."
receipt=`./rpc.sh --deploy "$PRIVATE_KEY" "$NONCE" "$STAKER_JAR_PATH"`
require_success $?

echo "Deployment transaction hash: \"$receipt\".  Waiting for deployment to complete..."
address=""
while [ "" == "$address" ]
do
	echo " waiting..."
	sleep 1
	address=`./rpc.sh --get-receipt-address "$receipt"`
	require_success $?
done
echo "StakerRegistry was deployed to address: \"$address\""
if [ "$EXPECTED_STAKER_REGISTRY_ADDRESS" != "$address" ]
then
	echo "Address was incorrect:  Expected $EXPECTED_STAKER_REGISTRY_ADDRESS"
	exit 1
fi

echo "Deploying the poolRegistry.jar..."
NONCE=$((NONCE + 1))
receipt=`./rpc.sh --deploy "$PRIVATE_KEY" "$NONCE" "$POOL_JAR_PATH" "$address"`
require_success $?

echo "Deployment transaction hash: \"$receipt\".  Waiting for deployment to complete..."
address=""
while [ "" == "$address" ]
do
	echo " waiting..."
	sleep 1
	address=`./rpc.sh --get-receipt-address "$receipt"`
	require_success $?
done
echo "PoolRegistry was deployed to address: \"$address\""

echo "Deployment complete."
