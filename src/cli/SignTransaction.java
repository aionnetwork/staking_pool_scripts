package cli;

import java.math.BigInteger;

import net.i2p.crypto.eddsa.Utils;
import support.SignedTransactionBuilder;


public class SignTransaction {
    private static final long ENERGY_LIMIT_DEPLOY = 5_000_000L;
    private static final long ENERGY_LIMIT_CALL = 2_000_000L;
    private static final long ENERGY_PRICE = 10_000_000_000L;

    public static void main(String[] args) throws Exception {
        byte[] senderPrivateKey = findBytes(args, "--privateKey", true);
        byte[] senderNonce = findBytes(args, "--nonce", true);
        byte[] destinationAddress = findBytes(args, "--destination", false);
        byte[] dataToDeploy = findBytes(args, "--deploy", false);
        byte[] dataToCall = findBytes(args, "--call", false);
        byte[] value = findBytes(args, "--value", false);
        
        // Setup the transaction.
        SignedTransactionBuilder transactionBuilder = new SignedTransactionBuilder()
                .privateKey(senderPrivateKey)
                .senderNonce(new BigInteger(1, senderNonce))
                .energyLimit((null != dataToDeploy) ? ENERGY_LIMIT_DEPLOY : ENERGY_LIMIT_CALL)
                .energyPrice(ENERGY_PRICE);
        if (null != dataToDeploy) {
            transactionBuilder = transactionBuilder.data(dataToDeploy);
        } else if (null != dataToCall) {
            transactionBuilder = transactionBuilder
                    .destination(destinationAddress)
                    .data(dataToCall);
        }
        if (null != value) {
            transactionBuilder = transactionBuilder.value(new BigInteger(1, value));
        }
        
        // Create the signed transaction.
        byte[] signedTransaction = transactionBuilder.buildSignedTransaction();
        
        // Render this as a hex string and print it.
        String hexStringOfSignedTransaction = Utils.bytesToHex(signedTransaction);
        System.out.println(hexStringOfSignedTransaction);
    }


    private static byte[] findBytes(String[] args, String name, boolean required) {
        byte[] value = null;
        for (int i = 0; i < args.length; ++i) {
            String arg = args[i];
            if (name.equals(arg)) {
                // Grab the next argument as hex.
                value = Utils.hexToBytes(args[i + 1]);
                System.out.println("LENGTH: " + args[i+1].length());
            }
        }
        if (required && (null == value)) {
            System.err.println("Missing required argument: \"" + name + "\"");
            System.err.println("Usage: cli.SignTransaction --privateKey <key> --nonce <nonce> [--destination <destination>] [--deploy <data_to_deploy>] [--call <data_to_send_as_call>] [--value <value_to_transfer>]");
            System.exit(1);
        }
        return value;
    }
}
