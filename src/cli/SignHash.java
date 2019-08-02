package cli;

import java.math.BigInteger;
import java.security.InvalidKeyException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SignatureException;
import java.security.spec.PKCS8EncodedKeySpec;
import java.util.Arrays;
import net.i2p.crypto.eddsa.EdDSAEngine;
import net.i2p.crypto.eddsa.EdDSAPrivateKey;
import net.i2p.crypto.eddsa.Utils;
import net.i2p.crypto.eddsa.spec.EdDSANamedCurveTable;
import net.i2p.crypto.eddsa.spec.EdDSAParameterSpec;

public class SignHash {

    public static void main(String[] args) throws Exception {

        byte[] stakerPrivateKey = findBytes(args, "--privateKey", true);
        byte[] oldSeed = findBytes(args, "--signSeed", false);
        byte[] sealingHash = findBytes(args, "--signSealingHash", false);

        if (oldSeed == null && sealingHash == null) {
            System.err.println(
                    "Missing required argument: \"" + "signSeed or signSealingHash" + "\"");
            System.err.println("Usage: cli.SignHash --privateKey <key> --signSeed <currentSeed>");
            System.err.println("  or  ");
            System.err.println(
                    "Usage: cli.SignHash --privateKey <key> --signSealingHash <sealingHash>");
            System.exit(1);
        }

        EdDSAPrivateKey privateKey =
                new EdDSAPrivateKey(new PKCS8EncodedKeySpec(addSkPrefix(stakerPrivateKey)));

        byte[] signature;
        if (oldSeed != null) {
            signature = sign(privateKey, oldSeed);
        } else {
            signature = sign(privateKey, sealingHash);
        }

        // Render this as a hex string and print it.
        String hexStringOfSigunature = "0x" + Utils.bytesToHex(signature);
        System.out.println(hexStringOfSigunature);
    }

    private static byte[] findBytes(String[] args, String name, boolean required) {
        byte[] value = null;
        for (int i = 0; i < args.length; ++i) {
            String arg = args[i];
            if (name.equals(arg)) {
                // Grab the next argument.
                String nextArg = args[i + 1];

                // We interpret it as hex-encoded binary if it has a 0x prefix or a BigInteger we
                // should
                // return as big-endian bytes, if not.
                if (nextArg.startsWith("0x")) {
                    // Hex, so strip this prefix and use the crypt util to get the bytes.
                    value = Utils.hexToBytes(nextArg.substring(2));
                } else {
                    // Interpret this as a BigInteger.
                    value = new BigInteger(nextArg).toByteArray();
                }
            }
        }
        if (required && (null == value)) {
            System.err.println("Missing required argument: \"" + name + "\"");
            System.exit(1);
        }
        return value;
    }

    private static byte[] addSkPrefix(byte[] skString) {
        byte[] skEncoded = Utils.hexToBytes("302e020100300506032b657004220420");
        byte[] encoded = Arrays.copyOf(skEncoded, skEncoded.length + skString.length);
        System.arraycopy(skString, 0, encoded, skEncoded.length, skString.length);
        return encoded;
    }

    private static byte[] sign(EdDSAPrivateKey privateKey, byte[] data)
            throws InvalidKeyException, SignatureException, NoSuchAlgorithmException {
        EdDSAParameterSpec spec = EdDSANamedCurveTable.getByName(EdDSANamedCurveTable.ED_25519);
        EdDSAEngine edDSAEngine =
                new EdDSAEngine(MessageDigest.getInstance(spec.getHashAlgorithm()));
        edDSAEngine.initSign(privateKey);
        return edDSAEngine.signOneShot(data);
    }
}
