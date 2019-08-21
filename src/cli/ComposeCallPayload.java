package cli;

import java.math.BigInteger;

import org.aion.avm.userlib.abi.ABIStreamingEncoder;

import avm.Address;
import net.i2p.crypto.eddsa.Utils;


/**
 * Creates an ABI-encoded call payload when given a method name and 0 or more Addresses as hex strings.
 */
public class ComposeCallPayload {
    public static void main(String[] args) {
        if (0 == args.length) {
            System.err.println("Usage: cli.ComposeCallPayload METHOD_NAME [ ADDRESS_PARAMETER]*");
            System.exit(1);
        }
        
        String methodName = args[0];
        ABIStreamingEncoder encoder = new ABIStreamingEncoder();
        encoder.encodeOneString(methodName);
        for (int i = 1; i < args.length; ++i) {
            Address address = readAsAddress(args[i]);
            encoder.encodeOneAddress(address);
        }
        byte[] rawCallData = encoder.toBytes();
        System.out.println("0x" + Utils.bytesToHex(rawCallData));
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
