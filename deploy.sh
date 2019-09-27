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
TOOLS_JAR=Tools.jar

function require_success()
{
	if [ $1 -ne 0 ]
	then
		echo "Failed"
		exit 1
	fi
}

MIN_SELF_STAKE=1000000000000000000000
SIGNING_ADDRESS_COOLING_PERIOD="$((6 * 60 * 24 * 7))"
UNDELEGATE_LOCK_UP_PERIOD="$((6 * 60 * 24 * 7))"
TRANSFER_LOCK_UP_PERIOD="$((6 * 10))"
COMMISSION_RATE_CHANGE_TIME_LOCK_PERIOD="$((6 * 60 * 24 * 7))"
MIN_SELF_STAKE_PERCENTAGE=1
POOL_COINBASE="00000872504b0304140008080800d4ad282b000000000000000000000000140004004d4554412d494e462f4d414e49464553542e4d46feca0000f34dcccb4c4b2d2ed10d4b2d2acecccfb35230d433e0e5f24dccccd375ce492c2eb65270e4e5e2e50200504b07082bc2bf352a00000028000000504b0304140008080800d4ad282b00000000000000000000000007000000412e636c6173736d525b53d340183ddb16d28600e52a888a777b51aa88152ca2b480b614418a748007270d4b08a4a9262933fe14df7cf35574a666d4f1d519ff938edfa6958b636692c99e3d7bf67ce7fb7efefef21d401a6506362b813144f7d4033565aa969e5aaeec71cd951064e859a9d5cc5ccdb02aaac3c704850ed0db59540faaa9d9ed6d9b3b4e86613856f4cf575577379535f4bce5729ddb99f83a4397a066cd9ab6afedaa862521c210d1b99b534d93db0cddb1f82935051d5064c8e854d00e298200ba193a4e5024f430b4f3d775d57418065a779ff09e896f2ae843bf8c5e0c304836710d9b3384629bf175056730242e1866e8ff9f6d0923a4ef18ba55af320463f1bc82f3b820e31c46197ac9fb2aaf522986a5cf5bdcd6dff8a482824bb82c74afd0451a55c730113b55daff43daca169a09ac72a76eba14c0355c173a3718e4635c429c82339c525dd348ccbf93ca4ce2a68c046e51632a3e4691b7dbfc80dbae823bb82d84c619c2d39a498edd19e26525dca354a88e39d555452af1adac82fb9814e4293a3fdda2b6c5b6b222b00ca6651a9787747847c123d19f341ed3491103811a25496d3cee43c9b5291d2a258739c19d5790125e0278726ad69a3c097972e8daaae5ec703b8c451905d138a6330cfdd5fd373605cfb02cb457c49c8485f62a39cad5b6a9d19d2557d5f697d4576b6ac5a4b55caad56d8d2f1826a72e0510a2f127540c18fd8510111284acd12a8f366200e31eba3e22dac0a087b389062e86de410abd4728486bda4804bf853d5cf5102b261b1823f0d0577d415f5218a27c22a2ea966c14cd27e4e1eea1ff17c6c4d1ee28823ed6f715e90d0f0f3e6366a381d94f88969be408b2986c91cb44160ea78ec98b6470a198fc01d9c35332f621d95b6c60e92d7a12a4f3fc65d94349c0addd23a30a02bf3022212da13048d83a6101b4fd01504b070883a60cdea902000022040000504b0304140008080800d4ad282b00000000000000000000000007000000422e636c6173739d54db4e1351145da73375ca5064d0522e2d5a0a423b148a200a02261463d2a4e80386a4f220433b966269491988bc18e32ff001121243627c8044a81182efbefb01fe4723ee33bd0d501363d399d97b9f7d5b7b9d737efcfe7606e03e1e31b08804c6a0ac6a5b5a38a36553e167cbab7ac290203034cf44a28ff5442ea9e787b803b92fd3131528fa9c8404171c2424196c8b111274866b53e96cdaa0d4f6c06224b8c02004820b4e5c872243448b138d7036c0869b4e3441e2522b832b108cd55a9837f2e96c6a923bb4c9e4d07ea1c1d2aa844e33f53c555d71a28ba7b7e1166969277c25ad9bb459093d327a4b85bddcda7731dbf686a1af4908303468f9bcb69dc8ad6f33a881d8e5914c46eb98a21c9b8a0119418438ca66191e0c51e157343f42a56dad856792c9bcbeb131c9d06851258cc818357d530ced9509ac69c64a38924e45b3869ed2f314e4aa6797f040c6388f6e9acd65370c2d6b2c68994d22409c25c2c83c6f6889d773dafa736d3943ba3c9fdbcc27f427e98c8e6e1a8348dc89e8c435d00ec043d26c7090de60d1f9b8882e5326b238dbb44620e93d499a87ec36fa36ab05dc50078ee0528523b80fc17f3450b4951d27ca8e5d4cfd02d7473805fe3ddba5dd13db87433d46476ce0c00c9aa2b70ca1452c4294cc0ac45b358d68a619e4d1f4b84715c79b9d294f451597465b70fef6ddce941a27d5be44cd783e97bb69aa76f3137613fe276afb363d7e16ab251cd985cf924fe9de8552cbb68f2d73911b5e88dc421e1fd07882de780177be9bb07868d2be67b116d03f5d5bf25a96bca78ea795728382f72b61e3b9bd3cf5093cf1c102c2d6d174c05ec498dddb5aa403704e1bdb26f1bfc77418c6dd32c40382c84fe74e05e205807e2b40ff2e715705c8f9787905a2bf2e44c56701a2f84e1d7395bc2141f155a028be1296d178a8807b562c8d10c7bcee22fa253a070c63742595baff5526e8f85f08eab944d0fb2bddf7d4ed5edcbb68b586fc1759e39cac89bf90d567216bdc3c50746595e10e93c6e8db79f974540b1f5653d20168a124fc8a2b4787cad16df5f75e2d54007393386d56b7ff01504b0708f73eff920f03000006060000504b0304140008080800d4ad282b00000000000000000000000007000000432e636c6173733d4ebb0ac240109c358991181f69d3d9a985e9ac44d0a0a0a542fa239e72122fa217f1b7ac040b3fc08f12d7082eec6386d9d97dbd1f4f004304048a5d1021dc8b8b8832a177d1aad0461de4ec9acaa351b976611182c974f167065f31af6e39970e7ec126d591d2ca8c0956b797f8f050f760c32734e25c9f8dd02611592109769c6fb879ebbc38a572ae32890e2aac651b84a8827f42935105359ee86bc5b5c54c5062c0e9dfd1b8fd2ea35d4a9d0f504b0708d8f1b600b0000000d8000000504b01021400140008080800d4ad282b2bc2bf352a000000280000001400040000000000000000000000000000004d4554412d494e462f4d414e49464553542e4d46feca0000504b01021400140008080800d4ad282b83a60cdea902000022040000070000000000000000000000000070000000412e636c617373504b01021400140008080800d4ad282bf73eff920f0300000606000007000000000000000000000000004e030000422e636c617373504b01021400140008080800d4ad282bd8f1b600b0000000d8000000070000000000000000000000000092060000432e636c617373504b05060000000004000400e500000077070000000000000021220000000000000000000000000000000000000000000000000000000000000000"
echo "Deploying the stakerRegistry.jar..."
callPayload="$(java -cp $TOOLS_JAR cli.ComposeCallPayload "deployStakerRegistry" "$MIN_SELF_STAKE" "$SIGNING_ADDRESS_COOLING_PERIOD" "$UNDELEGATE_LOCK_UP_PERIOD" "$TRANSFER_LOCK_UP_PERIOD")"
receipt=`./rpc.sh --deploy "$PRIVATE_KEY" "$NONCE" "$STAKER_JAR_PATH" "$callPayload"`
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
callPayload="$(java -cp $TOOLS_JAR cli.ComposeCallPayload "deployPoolRegistry" "$address" "$MIN_SELF_STAKE" "$MIN_SELF_STAKE_PERCENTAGE" "$COMMISSION_RATE_CHANGE_TIME_LOCK_PERIOD" "$POOL_COINBASE")"
receipt=`./rpc.sh --deploy "$PRIVATE_KEY" "$NONCE" "$POOL_JAR_PATH" "$callPayload"`
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
