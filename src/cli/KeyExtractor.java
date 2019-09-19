package cli;

import net.i2p.crypto.eddsa.Utils;
import support.PrivateKey;

import java.security.spec.InvalidKeySpecException;

public class KeyExtractor {
    public static void main(String[] args) {
        if (0 == args.length) {
            System.err.println("Usage: cli.KeyExtractor PRIVATE_KEY");
            System.exit(1);
        }

        try {
            String private_key = args[0].startsWith("0x") ? args[0].substring(2) : args[0];
            System.out.println("0x" + Utils.bytesToHex(PrivateKey.fromBytes(Utils.hexToBytes(private_key)).getAddress()));
        } catch (InvalidKeySpecException e) {
            e.printStackTrace();
        }
    }
}
