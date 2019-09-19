package support;

import net.i2p.crypto.eddsa.EdDSAPrivateKey;
import net.i2p.crypto.eddsa.Utils;

import java.nio.ByteBuffer;
import java.security.spec.InvalidKeySpecException;
import java.security.spec.PKCS8EncodedKeySpec;
import java.util.Arrays;

/**
 * An Aion private key corresponding to some Aion address.
 * <p>
 * A private key is immutable.
 */
public final class PrivateKey {
    private static final String skEncodedPrefix = "302e020100300506032b657004220420";
    private static final int SIZE = 32;

    private final byte[] privateKeyBytes;
    private final byte[] address;

    /**
     * Constructs a new private key consisting of the provided bytes.
     *
     * @param privateKeyBytes The bytes of the private key.
     */
    private PrivateKey(byte[] privateKeyBytes) throws InvalidKeySpecException {
        if (privateKeyBytes == null) {
            throw new NullPointerException("private key bytes cannot be null");
        }
        if (privateKeyBytes.length != SIZE) {
            throw new IllegalArgumentException("bytes of a private key must have a length of " + SIZE);
        }
        this.privateKeyBytes = copyByteArray(privateKeyBytes);
        this.address = deriveAddress(this.privateKeyBytes);
    }

    public static PrivateKey fromBytes(byte[] privateKeyBytes) throws InvalidKeySpecException {
        return new PrivateKey(privateKeyBytes);
    }

    public byte[] getAddress() {
        return this.address;
    }

    /**
     * Returns the bytes of this private key.
     *
     * @return The bytes of the private key.
     */
    public byte[] getPrivateKeyBytes() {
        return copyByteArray(this.privateKeyBytes);
    }

    private static byte[] copyByteArray(byte[] byteArray) {
        return Arrays.copyOf(byteArray, byteArray.length);
    }

    public static byte[] deriveAddress(byte[] privateKeyBytes) throws InvalidKeySpecException {
        if (privateKeyBytes == null) {
            throw new NullPointerException("private key cannot be null");
        }

        if (privateKeyBytes.length != 32) {
            throw new IllegalArgumentException("private key mute be 32 bytes");
        }

        EdDSAPrivateKey privateKey = new EdDSAPrivateKey(new PKCS8EncodedKeySpec(addSkPrefix(Utils.bytesToHex(privateKeyBytes))));
        byte[] publicKeyBytes = privateKey.getAbyte();

        return computeA0Address(publicKeyBytes);
    }

    /**
     * Add encoding prefix for importing private key
     */
    private static byte[] addSkPrefix(String skString) {
        String skEncoded = skEncodedPrefix + skString;
        return Utils.hexToBytes(skEncoded);
    }

    private static byte[] computeA0Address(byte[] publicKey) {
        byte A0_IDENTIFIER = (byte) 0xa0;
        ByteBuffer buf = ByteBuffer.allocate(32);
        buf.put(A0_IDENTIFIER);
        buf.put(blake256(publicKey), 1, 31);
        return buf.array();
    }

    private static byte[] blake256(byte[] input) {
        Blake2b digest = Blake2b.Digest.newInstance(32);
        digest.update(input);
        return digest.digest();
    }

    @Override
    public boolean equals(Object other) {
        if (!(other instanceof PrivateKey)) {
            return false;
        }
        if (other == this) {
            return true;
        }

        PrivateKey otherPrivateKey = (PrivateKey) other;
        return Arrays.equals(this.privateKeyBytes, otherPrivateKey.getPrivateKeyBytes());
    }

    @Override
    public int hashCode() {
        return Arrays.hashCode(this.privateKeyBytes);
    }
}

