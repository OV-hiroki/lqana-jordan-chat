package io.grpc.util;

import com.google.common.io.BaseEncoding;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.security.KeyFactory;
import java.security.NoSuchAlgorithmException;
import java.security.PrivateKey;
import java.security.cert.Certificate;
import java.security.cert.CertificateException;
import java.security.cert.CertificateFactory;
import java.security.cert.X509Certificate;
import java.security.spec.InvalidKeySpecException;
import java.security.spec.PKCS8EncodedKeySpec;
import java.util.Collection;

/* JADX INFO: loaded from: classes8.dex */
public final class CertificateUtils {
    public static X509Certificate[] getX509Certificates(InputStream inputStream) throws CertificateException {
        CertificateFactory factory = CertificateFactory.getInstance("X.509");
        Collection<? extends Certificate> certs = factory.generateCertificates(inputStream);
        return (X509Certificate[]) certs.toArray(new X509Certificate[0]);
    }

    public static PrivateKey getPrivateKey(InputStream inputStream) throws InvalidKeySpecException, NoSuchAlgorithmException, IOException {
        String line;
        BufferedReader reader = new BufferedReader(new InputStreamReader(inputStream, "UTF-8"));
        do {
            line = reader.readLine();
            if (line == null) {
                break;
            }
        } while (!"-----BEGIN PRIVATE KEY-----".equals(line));
        StringBuilder keyContent = new StringBuilder();
        while (true) {
            String line2 = reader.readLine();
            if (line2 == null || "-----END PRIVATE KEY-----".equals(line2)) {
                break;
            }
            keyContent.append(line2);
        }
        byte[] decodedKeyBytes = BaseEncoding.base64().decode(keyContent.toString());
        PKCS8EncodedKeySpec keySpec = new PKCS8EncodedKeySpec(decodedKeyBytes);
        try {
            return KeyFactory.getInstance("RSA").generatePrivate(keySpec);
        } catch (InvalidKeySpecException e) {
            try {
                return KeyFactory.getInstance("EC").generatePrivate(keySpec);
            } catch (InvalidKeySpecException e2) {
                throw new InvalidKeySpecException("Neither RSA nor EC worked", e2);
            }
        }
    }
}
