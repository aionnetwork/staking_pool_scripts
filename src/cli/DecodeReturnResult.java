package cli;

import net.i2p.crypto.eddsa.Utils;
import org.aion.avm.userlib.abi.ABIDecoder;

public class DecodeReturnResult {
    public static void main(String[] args) {
        if (0 == args.length) {
            System.err.println("Usage: cli.DecodeReturnResult TYPE VALUE");
            System.exit(1);
        }

        String result = null;
        String type = args[0];
        switch (type) {
            case "BigInteger":
                result = getDecodedBigInteger(args[1]);
                break;
            default:
                System.err.println("Type " + type + " is not defined.");
                System.exit(1);
        }
        System.out.println(result);
    }

    private static String getDecodedBigInteger(String value) {
        if (value.startsWith("0x")) {
            value = value.substring(2);
        }
        return new ABIDecoder(Utils.hexToBytes(value)).decodeOneBigInteger().toString();
    }

}
