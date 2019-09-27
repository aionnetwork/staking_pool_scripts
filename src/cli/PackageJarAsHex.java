package cli;

import net.i2p.crypto.eddsa.Utils;
import org.aion.avm.userlib.CodeAndArguments;

import java.io.File;
import java.nio.file.Files;


/**
 * Given a path to a JAR, will package it inside a CodeAndArguments structure and print the serialized
 * representation of this complete package as a hex string.
 */
public class PackageJarAsHex {
    public static void main(String[] args) throws Exception {
        if (0 == args.length) {
            System.err.println("Usage: cli.PackageJarAsHex path/to/jar [CONTRACT_NAME] [PARAMETER]");
            System.exit(1);
        }

        // Read the JAR.
        byte[] jarBytes = Files.readAllBytes(new File(args[0]).toPath());

        byte[] argument = new byte[0];
        if (args.length == 2) {
            argument = Utils.hexToBytes(args[1].startsWith("0x") ? args[1].substring(2) : args[1]);
        }
        // Create the CodeAndArguments structure.
        byte[] packaged = new CodeAndArguments(jarBytes, argument).encodeToBytes();
        
        // Render this as a hex string and print it.
        String hexStringOfSignedTransaction = "0x" + Utils.bytesToHex(packaged);
        System.out.println(hexStringOfSignedTransaction);
    }
}
