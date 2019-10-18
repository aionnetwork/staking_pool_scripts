#!/bin/bash

PRIVATE_KEY="0xcc76648ce8798bc18130bc9d637995e5c42a922ebeab78795fac58081b9cf9d4"
PUBLIC_KEY="0x069346ca77152d3e42b1630826feef365683038c3b00ff20b0ea42d7c121fa9f"
TOOLS_JAR=Tools.jar
NODE_ADDRESS="127.0.0.1:8545"

function require_success()
{
        if [ $1 -ne 0 ]
        then
                echo "Failed"
                exit 1
        fi
}

echo "Get current seed..."

seed=`./rpc.sh --getseed "$NODE_ADDRESS"`
require_success $?

echo "returned seed: \"$seed\"."

newSeed="$(java -cp $TOOLS_JAR cli.SignHash --privateKey "$PRIVATE_KEY" --signSeed "$seed")"
if [ $? -ne 0 ]
then
	exit 1
fi

echo "Get new seed: \"$newSeed\"."

echo "Submit new seed..."

sealingHash=`./rpc.sh --submitseed $newSeed $PUBLIC_KEY "$NODE_ADDRESS"`
require_success $?

echo "returned sealinghash: \"$sealingHash\"."

signature="$(java -cp $TOOLS_JAR cli.SignHash --privateKey "$PRIVATE_KEY" --signSealingHash "$sealingHash")"
if [ $? -ne 0 ]
then
        exit 1
fi

echo "Submit signature for sealing the new staking block..."

result=`./rpc.sh --submitsignature $signature $sealingHash "$NODE_ADDRESS"`
if [ $? -ne 0 ]
then
        exit 1
fi

echo "Signature submit result: \"$result\"."
