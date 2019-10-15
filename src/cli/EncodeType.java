package cli;

import net.i2p.crypto.eddsa.Utils;
import org.aion.avm.userlib.abi.ABIEncoder;

import java.math.BigInteger;

public class EncodeType {
    public static void main(String[] args) {
        if (0 == args.length) {
            System.err.println("Usage: cli.EncodeType Type");
            System.exit(1);
        }

        byte[] rawCallData = null;
        String type = args[0];
        switch (type) {
            case "BigInteger":
                rawCallData = ABIEncoder.encodeOneBigInteger(new BigInteger(args[1]));
                break;
            default:
                System.err.println("Type " + type + " is not defined.");
                System.exit(1);
        }
        System.out.println("0x" + Utils.bytesToHex(rawCallData));
    }
}
