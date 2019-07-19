package cli;

import java.io.File;
import java.nio.file.Files;

import org.aion.avm.userlib.CodeAndArguments;

import net.i2p.crypto.eddsa.Utils;


/**
 * Given a path to a JAR, will package it inside a CodeAndArguments structure and print the serialized
 * representation of this complete package as a hex string.
 */
public class PackageJarAsHex {
    public static void main(String[] args) throws Exception {
        if (1 != args.length) {
            System.err.println("Usage: cli.PackageJarAsHex path/to/jar");
            System.exit(1);
        }
        
        // Read the JAR.
        byte[] jarBytes = Files.readAllBytes(new File(args[0]).toPath());
        
        // Create the CodeAndArguments structure.
        byte[] packaged = new CodeAndArguments(jarBytes, new byte[0]).encodeToBytes();
        
        // Render this as a hex string and print it.
        String hexStringOfSignedTransaction = "0x" + Utils.bytesToHex(packaged);
        System.out.println(hexStringOfSignedTransaction);
    }
}
