package cli;

import java.io.File;
import java.math.BigInteger;
import java.nio.file.Files;

import avm.Address;
import org.aion.avm.userlib.CodeAndArguments;

import net.i2p.crypto.eddsa.Utils;
import org.aion.avm.userlib.abi.ABIStreamingEncoder;


/**
 * Given a path to a JAR, will package it inside a CodeAndArguments structure and print the serialized
 * representation of this complete package as a hex string.
 */
public class PackageJarAsHex {
    public static void main(String[] args) throws Exception {
        if (0 == args.length) {
            System.err.println("Usage: cli.PackageJarAsHex path/to/jar [ADDRESS PARAMETER]");
            System.exit(1);
        }
        
        // Read the JAR.
        byte[] jarBytes = Files.readAllBytes(new File(args[0]).toPath());

        byte[] argument = new byte[0];
        if (args.length == 2) {
            ABIStreamingEncoder encoder = new ABIStreamingEncoder();
            Address address = readAsAddress(args[1]);
            encoder.encodeOneAddress(address);
            argument = encoder.toBytes();
        }
        // Create the CodeAndArguments structure.
        byte[] packaged = new CodeAndArguments(jarBytes, argument).encodeToBytes();
        
        // Render this as a hex string and print it.
        String hexStringOfSignedTransaction = "0x" + Utils.bytesToHex(packaged);
        System.out.println(hexStringOfSignedTransaction);
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
