package cli;

import java.math.BigInteger;

import org.aion.avm.userlib.abi.ABIStreamingEncoder;

import avm.Address;
import net.i2p.crypto.eddsa.Utils;


/**
 * Creates an ABI-encoded call payload when given a method name and 0 or more parameters.
 */
public class ComposeCallPayload {
    public static void main(String[] args) {
        if (0 == args.length) {
            System.err.println("Usage: cli.ComposeCallPayload METHOD_NAME [PARAMETER]*");
            System.exit(1);
        }

        byte[] rawCallData = null;
        String methodName = args[0];
        switch (methodName) {
            case "registerPool":
                rawCallData = getRegisterPoolPayload(args);
                break;
            case "delegate":
            case "bond":
            case "isActive":
            case "getTotalStake":
            case "registerStaker":
            case "getStake":
            case "getEffectiveStake":
            case "withdraw":
                rawCallData = getPayloadAddressParameter(args);
                break;
            case "undelegate":
                rawCallData = getUndelegatePayload(args);
                break;
            case "transferDelegation":
                rawCallData = getTransferDelegationPayload(args);
                break;
            case "finalizeUndelegate":
            case "finalizeTransfer":
                rawCallData = getFinalizePayload(args);
                break;
            default:
                System.err.println("Method " + methodName + " is not defined.");
                System.exit(1);
        }
        System.out.println("0x" + Utils.bytesToHex(rawCallData));
    }

    private static byte[] getPayloadAddressParameter(String[] args) {
        String methodName = args[0];
        ABIStreamingEncoder encoder = new ABIStreamingEncoder();
        encoder.encodeOneString(methodName);
        for (int i = 1; i < args.length; ++i) {
            Address address = readAsAddress(args[i]);
            encoder.encodeOneAddress(address);
        }
        return encoder.toBytes();
    }

    private static byte[] getRegisterPoolPayload(String[] args) {
        ABIStreamingEncoder encoder = new ABIStreamingEncoder();
        encoder.encodeOneString(args[0]);
        encoder.encodeOneAddress(readAsAddress(args[1]));
        encoder.encodeOneInteger(Integer.valueOf(args[2]));
        encoder.encodeOneByteArray(args[3].getBytes());
        encoder.encodeOneByteArray(Utils.hexToBytes(args[4]));
        return encoder.toBytes();
    }

    private static byte[] getUndelegatePayload(String[] args) {
        ABIStreamingEncoder encoder = new ABIStreamingEncoder();
        encoder.encodeOneString(args[0]);
        encoder.encodeOneAddress(readAsAddress(args[1]));
        encoder.encodeOneBigInteger(new BigInteger(args[2]));
        encoder.encodeOneBigInteger(new BigInteger(args[3]));
        return encoder.toBytes();
    }

    private static byte[] getTransferDelegationPayload(String[] args) {
        ABIStreamingEncoder encoder = new ABIStreamingEncoder();
        encoder.encodeOneString(args[0]);
        encoder.encodeOneAddress(readAsAddress(args[1]));
        encoder.encodeOneAddress(readAsAddress(args[2]));
        encoder.encodeOneBigInteger(new BigInteger(args[3]));
        encoder.encodeOneBigInteger(new BigInteger(args[4]));
        return encoder.toBytes();
    }

    private static byte[] getFinalizePayload(String[] args) {
        ABIStreamingEncoder encoder = new ABIStreamingEncoder();
        encoder.encodeOneString(args[0]);
        encoder.encodeOneLong(Long.valueOf(args[1]));
        return encoder.toBytes();
    }

    private static Address readAsAddress(String arg) {
        // We interpret it as hex-encoded binary if it has a 0x prefix or a BigInteger we should return as big-endian bytes, if not.
        byte[] rawBytes = (arg.startsWith("0x"))
                // Hex, so strip this prefix and use the crypt util to get the bytes.
                ? Utils.hexToBytes(arg.substring(2))
                // Interpret this as a BigInteger.
                : new BigInteger(arg).toByteArray();
        return new Address(rawBytes);
    }
}
