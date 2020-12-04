import android.security.keystore.KeyGenParameterSpec;
import android.security.keystore.KeyInfo;
import android.security.keystore.KeyProperties;
import android.util.Log;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.InvalidAlgorithmParameterException;
import java.security.Key;
import java.security.KeyFactory;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.NoSuchProviderException;
import java.security.UnrecoverableEntryException;
import java.security.UnrecoverableKeyException;
import java.security.cert.CertificateException;
import java.security.spec.InvalidKeySpecException;

import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.GCMParameterSpec;

public class CryptoUtils {

    private static final String ANDROID_KEY_STORE_PROVIDER = "AndroidKeyStore";
    private static final String KEY_ALIAS = "vault12.cryptonativestorage.keyalias";
    private static final String DELIMITER = "@~@~@";

    private static SecretKey generateKey() throws NoSuchProviderException, NoSuchAlgorithmException, InvalidAlgorithmParameterException {
        final KeyGenerator keyGenerator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, ANDROID_KEY_STORE_PROVIDER);
        final KeyGenParameterSpec keyGenParameterSpec = new KeyGenParameterSpec.Builder(KEY_ALIAS,
                KeyProperties.PURPOSE_ENCRYPT | KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setRandomizedEncryptionRequired(true)
                .build();
        keyGenerator.init(keyGenParameterSpec);
        final SecretKey secretKey = keyGenerator.generateKey();
        return secretKey;
    }

    private static SecretKey loadKey() throws KeyStoreException, CertificateException, NoSuchAlgorithmException, IOException, UnrecoverableEntryException {
        final KeyStore keyStore = KeyStore.getInstance(ANDROID_KEY_STORE_PROVIDER);
        keyStore.load(null);
        final KeyStore.SecretKeyEntry secretKeyEntry = (KeyStore.SecretKeyEntry) keyStore.getEntry(KEY_ALIAS, null);
        if (secretKeyEntry != null) {
            return secretKeyEntry.getSecretKey();
        } else {
            return null;
        }
    }

    private static SecretKey getKey() throws CertificateException, UnrecoverableEntryException, NoSuchAlgorithmException, KeyStoreException, IOException,
            NoSuchProviderException, InvalidAlgorithmParameterException {
        SecretKey key = null;
        key = loadKey();
        if (key == null) {
            key = generateKey();
        }
        return key;
    }

    public static String encrypt(String clearText) {
        final SecretKey secretKey;
        try {
            secretKey = getKey();
            final Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.ENCRYPT_MODE, secretKey);
            byte[] iv = cipher.getIV();
            byte[] encrypted = cipher.doFinal(clearText.getBytes(StandardCharsets.UTF_8));
            return String.format("%s%s%s", Crypto.toBase64(iv), DELIMITER, Crypto.toBase64(encrypted));
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }

    public static String decrypt(String ciphertext) {
        String[] fields = ciphertext.split(DELIMITER);
        if (fields.length != 2) {
            throw new IllegalArgumentException("Invalid encypted text format");
        }
        byte[] iv = Crypto.fromBase64(fields[0]);
        byte[] cipherBytes = Crypto.fromBase64(fields[1]);

        SecretKey secretKey = null;
        try {
            secretKey = getKey();
            final Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            final GCMParameterSpec spec = new GCMParameterSpec(128, iv);
            cipher.init(Cipher.DECRYPT_MODE, secretKey, spec);
            final byte[] decodedData = cipher.doFinal(cipherBytes);
            final String unencryptedString = new String(decodedData, StandardCharsets.UTF_8);
            return unencryptedString;
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }

    public static boolean isCypherText(String value) {
        return value.contains(DELIMITER);
    }

    public static boolean isKeyHardwareBacked() {
        try {
            final KeyStore keyStore = KeyStore.getInstance(ANDROID_KEY_STORE_PROVIDER);
            keyStore.load(null);
            SecretKey key = (SecretKey) keyStore.getKey(KEY_ALIAS, null);
            SecretKeyFactory factory = SecretKeyFactory.getInstance(key.getAlgorithm(), ANDROID_KEY_STORE_PROVIDER);
            KeyInfo info = (KeyInfo) factory.getKeySpec(key, KeyInfo.class);
            return info.isInsideSecureHardware();
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    public static void checkKeyIsHardwareBacked() {
        boolean isHardwareBacked = isKeyHardwareBacked();
        Log.w("CryptoUtils", "key is hardware backed: " + String.valueOf(isHardwareBacked));
    }

}