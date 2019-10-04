package cli;

import net.i2p.crypto.eddsa.Utils;
import support.Blake2b;

import java.io.File;
import java.nio.file.Files;

public class HashFile {

    public static void main(String[] args) throws Exception {
        if (0 == args.length) {
            System.err.println("Usage: cli.HashFile FILE_PATH");
            System.exit(1);
        }

        byte[] fileBytes = Files.readAllBytes(new File(args[0]).toPath());

        byte[] hash = blake2b(fileBytes);
        System.out.println("0x" + Utils.bytesToHex(hash));
    }
    
    public static byte[] blake2b(byte[] msg) {
        Blake2b digest = Blake2b.Digest.newInstance(32);
        digest.update(msg);
        return digest.digest();
    }
}
