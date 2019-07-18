package support;

import java.math.BigInteger;
import java.security.InvalidKeyException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SignatureException;
import java.security.spec.InvalidKeySpecException;
import java.security.spec.PKCS8EncodedKeySpec;
import java.util.Arrays;
import net.i2p.crypto.eddsa.EdDSAEngine;
import net.i2p.crypto.eddsa.EdDSAPrivateKey;
import net.i2p.crypto.eddsa.Utils;
import net.i2p.crypto.eddsa.spec.EdDSANamedCurveTable;
import net.i2p.crypto.eddsa.spec.EdDSAParameterSpec;
import org.aion.rlp.RLP;
import org.aion.rlp.RLPList;


/**
 * NOTE:  This is mostly just a copy of this utility:  https://github.com/aionick/OfflineTransactionSigner/blob/master/src/main/SignedTransactionBuilder.java
 * (in the future, we need to make a canonical version of this)
 * 
 * A convenience class for building an Aion transaction and signing it locally (offline) using a
 * private key.
 *
 * In general, if a specific method is invoked multiple times before building the transaction, then
 * the last invocation takes precedence.
 *
 * The builder can be used to construct additional transactions after each build, and the previous
 * build settings will apply.
 *
 * The builder provides a {@code reset} method that will clear the build back to its initial state.
 *
 * The sender of the transaction will be the Aion account that corresponds to the provided private
 * key.
 */
public final class SignedTransactionBuilder {
    private static final byte AION_ADDRESS_PREFIX = (byte) 0xa0;

    // Required fields.
    private byte[] privateKey = null;
    private BigInteger nonce = null;
    private long energyLimit = -1;

    // Fields we provide default values for.
    private BigInteger value = null;
    private byte[] destination = null;
    private byte[] data = null;
    private long energyPrice = -1;
    private byte type = 0x1;

    /**
     * The private key used to sign the transaction with.
     *
     * <b>This field must be set.</b>
     *
     * @param privateKey The private key.
     * @return this builder.
     */
    public SignedTransactionBuilder privateKey(byte[] privateKey) {
        this.privateKey = privateKey;
        return this;
    }

    /**
     * The destination address of the transaction.
     *
     * <b>This field must be set.</b>
     *
     * @param destination The destination.
     * @return this builder.
     */
    public SignedTransactionBuilder destination(byte[] destination) {
        this.destination = destination;
        return this;
    }

    /**
     * The amount of value to transfer from the sender to the destination.
     *
     * @param value The amount of value to transfer.
     * @return this builder.
     */
    public SignedTransactionBuilder value(BigInteger value) {
        this.value = value;
        return this;
    }

    /**
     * The nonce of the sender.
     *
     * <b>This field must be set.</b>
     *
     * @param nonce The sender nonce.
     * @return this builder.
     */
    public SignedTransactionBuilder senderNonce(BigInteger nonce) {
        this.nonce = nonce;
        return this;
    }

    /**
     * The transaction data.
     *
     * @param data The data.
     * @return this builder.
     */
    public SignedTransactionBuilder data(byte[] data) {
        this.data = data;
        return this;
    }

    /**
     * The energy limit of the transaction.
     *
     * <b>This field must be set.</b>
     *
     * @param limit The energy limit.
     * @return this builder.
     */
    public SignedTransactionBuilder energyLimit(long limit) {
        this.energyLimit = limit;
        return this;
    }

    /**
     * The energy price of the transaction.
     *
     * @param price The energy price.
     * @return this builder.
     */
    public SignedTransactionBuilder energyPrice(long price) {
        this.energyPrice = price;
        return this;
    }

    /**
     * Sets the transaction type to be the type used by the AVM.
     *
     * @return this builder.
     */
    public SignedTransactionBuilder useAvmTransactionType() {
        this.type = 0x2;
        return this;
    }

    /**
     * Constructs a transaction whose fields correspond to the fields as they have been set by the
     * provided builder methods, and signs this transaction with the provided private key.
     *
     * The following fields must be set prior to calling this method:
     *   - private key
     *   - nonce
     *   - energy limit
     *
     * The following fields, if not set, will have the following default values:
     *   - value: {@link BigInteger#ZERO}
     *   - destination: empty array
     *   - data: empty array
     *   - energy price: {@code 10_000_000_000L} (aka. 10 AMP)
     *   - type: {@code 0x1}
     *
     * @return the bytes of the signed transaction.
     */
    public byte[] buildSignedTransaction() throws InvalidKeySpecException, InvalidKeyException, SignatureException, NoSuchAlgorithmException {
        if (this.privateKey == null) {
            throw new IllegalStateException("No private key specified.");
        }
        if (this.nonce == null) {
            throw new IllegalStateException("No nonce specified.");
        }
        if (this.energyLimit == -1) {
            throw new IllegalStateException("No energy limit specified.");
        }

        EdDSAPrivateKey privateKey = new EdDSAPrivateKey(new PKCS8EncodedKeySpec(addSkPrefix(this.privateKey)));

        byte[] publicKey = privateKey.getAbyte();
        byte[] addrBytes = blake2b(publicKey);
        addrBytes[0] = AION_ADDRESS_PREFIX;

        byte[] to = (this.destination == null) ? new byte[0] : this.destination;
        byte[] value = (this.value == null) ? BigInteger.ZERO.toByteArray() : this.value.toByteArray();

        byte[] nonce = this.nonce.toByteArray();
        byte[] timestamp = BigInteger.valueOf(System.currentTimeMillis() * 1000).toByteArray();

        byte[] encodedNonce = RLP.encodeElement(nonce);
        byte[] encodedTo = RLP.encodeElement(to);
        byte[] encodedValue = RLP.encodeElement(value);
        byte[] encodedData = RLP.encodeElement((this.data == null) ? new byte[0] : this.data);
        byte[] encodedTimestamp = RLP.encodeElement(timestamp);
        byte[] encodedEnergy = RLP.encodeLong(this.energyLimit);
        byte[] encodedEnergyPrice = RLP.encodeLong((this.energyPrice == -1) ? 10_000_000_000L : this.energyPrice);
        byte[] encodedType = RLP.encodeByte(this.type);

        byte[] fullEncoding = RLP.encodeList(encodedNonce, encodedTo, encodedValue, encodedData, encodedTimestamp, encodedEnergy, encodedEnergyPrice, encodedType);

        byte[] rawHash = blake2b(fullEncoding);
        byte[] signatureOnly = sign(privateKey, rawHash);
        byte[] preEncodeSignature = new byte[publicKey.length + signatureOnly.length];
        System.arraycopy(publicKey, 0, preEncodeSignature, 0, publicKey.length);
        System.arraycopy(signatureOnly, 0, preEncodeSignature, publicKey.length, signatureOnly.length);
        byte[] signature = RLP.encodeElement(preEncodeSignature);

        return RLP.encodeList(encodedNonce, encodedTo, encodedValue, encodedData, encodedTimestamp, encodedEnergy, encodedEnergyPrice, encodedType, signature);
    }

    /**
     * Returns the transaction hash of the provided signed transaction, if this is a valid signed
     * transaction.
     *
     * It is assumed that {@code signedTransaction} is the output of the
     * {@code buildSignedTransaction()} method.
     *
     * @param signedTransaction A signed transaction.
     * @return the transaction hash of the signed transaction.
     * @throws NullPointerException if signedTransaction is null.
     * @throws IllegalStateException if the provided bytes could not be interpreted.
     */
    public static byte[] getTransactionHashOfSignedTransaction(byte[] signedTransaction) {
        if (signedTransaction == null) {
            throw new NullPointerException("cannot extract hash from a null transaction.");
        }

        RLPList decodedTransactionComponents = RLP.decode2(signedTransaction);

        if (decodedTransactionComponents.size() == 0) {
            throw new IllegalStateException("failed to interpret the provided RLP-encoded transaction.");
        }

        return blake2b(decodedTransactionComponents.get(0).getRLPData());
    }

    /**
     * Resets the builder so that it is in its initial state.
     *
     * The state of the builder after a call to this method is the same as the state of a newly
     * constructed builder.
     */
    public void reset() {
        this.privateKey = null;
        this.nonce = null;
        this.energyLimit = -1;
        this.value = null;
        this.destination = null;
        this.data = null;
        this.energyPrice = -1;
        this.type = 0x1;
    }

    private static byte[] addSkPrefix(byte[] skString) {
        byte[] skEncoded = Utils.hexToBytes("302e020100300506032b657004220420");
        byte[] encoded = Arrays.copyOf(skEncoded, skEncoded.length + skString.length);
        System.arraycopy(skString, 0, encoded, skEncoded.length, skString.length);
        return encoded;
    }

    private static byte[] blake2b(byte[] msg) {
        Blake2b.Digest digest = Blake2b.Digest.newInstance(32);
        digest.update(msg);
        return digest.digest();
    }

    private static byte[] sign(EdDSAPrivateKey privateKey, byte[] data) throws InvalidKeyException, SignatureException, NoSuchAlgorithmException {
        EdDSAParameterSpec spec = EdDSANamedCurveTable.getByName(EdDSANamedCurveTable.ED_25519);
        EdDSAEngine edDSAEngine = new EdDSAEngine(MessageDigest.getInstance(spec.getHashAlgorithm()));
        edDSAEngine.initSign(privateKey);
        return edDSAEngine.signOneShot(data);
    }
}
