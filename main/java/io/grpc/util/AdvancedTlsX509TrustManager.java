package io.grpc.util;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.net.Socket;
import java.security.GeneralSecurityException;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.TimeUnit;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.net.ssl.SSLEngine;
import javax.net.ssl.SSLParameters;
import javax.net.ssl.SSLSocket;
import javax.net.ssl.TrustManager;
import javax.net.ssl.TrustManagerFactory;
import javax.net.ssl.X509ExtendedTrustManager;

/* JADX INFO: loaded from: classes8.dex */
public final class AdvancedTlsX509TrustManager extends X509ExtendedTrustManager {
    private static final Logger log = Logger.getLogger(AdvancedTlsX509TrustManager.class.getName());
    private volatile X509ExtendedTrustManager delegateManager;
    private final SslSocketAndEnginePeerVerifier socketAndEnginePeerVerifier;
    private final Verification verification;

    public interface Closeable extends java.io.Closeable {
        @Override // java.io.Closeable, java.lang.AutoCloseable
        void close();
    }

    public interface SslSocketAndEnginePeerVerifier {
        void verifyPeerCertificate(X509Certificate[] x509CertificateArr, String str, Socket socket) throws CertificateException;

        void verifyPeerCertificate(X509Certificate[] x509CertificateArr, String str, SSLEngine sSLEngine) throws CertificateException;
    }

    public enum Verification {
        CERTIFICATE_AND_HOST_NAME_VERIFICATION,
        CERTIFICATE_ONLY_VERIFICATION,
        INSECURELY_SKIP_ALL_VERIFICATION
    }

    private AdvancedTlsX509TrustManager(Verification verification, SslSocketAndEnginePeerVerifier socketAndEnginePeerVerifier) throws CertificateException {
        this.delegateManager = null;
        this.verification = verification;
        this.socketAndEnginePeerVerifier = socketAndEnginePeerVerifier;
    }

    @Override // javax.net.ssl.X509TrustManager
    public void checkClientTrusted(X509Certificate[] chain, String authType) throws CertificateException {
        throw new CertificateException("Not enough information to validate peer. SSLEngine or Socket required.");
    }

    @Override // javax.net.ssl.X509ExtendedTrustManager
    public void checkClientTrusted(X509Certificate[] chain, String authType, Socket socket) throws CertificateException {
        checkTrusted(chain, authType, null, socket, false);
    }

    @Override // javax.net.ssl.X509ExtendedTrustManager
    public void checkClientTrusted(X509Certificate[] chain, String authType, SSLEngine engine) throws CertificateException {
        checkTrusted(chain, authType, engine, null, false);
    }

    @Override // javax.net.ssl.X509ExtendedTrustManager
    public void checkServerTrusted(X509Certificate[] chain, String authType, SSLEngine engine) throws CertificateException {
        checkTrusted(chain, authType, engine, null, true);
    }

    @Override // javax.net.ssl.X509TrustManager
    public void checkServerTrusted(X509Certificate[] chain, String authType) throws CertificateException {
        throw new CertificateException("Not enough information to validate peer. SSLEngine or Socket required.");
    }

    @Override // javax.net.ssl.X509ExtendedTrustManager
    public void checkServerTrusted(X509Certificate[] chain, String authType, Socket socket) throws CertificateException {
        checkTrusted(chain, authType, null, socket, true);
    }

    @Override // javax.net.ssl.X509TrustManager
    public X509Certificate[] getAcceptedIssuers() {
        if (this.delegateManager == null) {
            return new X509Certificate[0];
        }
        return this.delegateManager.getAcceptedIssuers();
    }

    public void useSystemDefaultTrustCerts() throws NoSuchAlgorithmException, CertificateException, KeyStoreException {
        this.delegateManager = createDelegateTrustManager(null);
    }

    public void updateTrustCredentials(X509Certificate[] trustCerts) throws GeneralSecurityException, IOException {
        KeyStore keyStore = KeyStore.getInstance(KeyStore.getDefaultType());
        keyStore.load(null, null);
        int i = 1;
        for (X509Certificate cert : trustCerts) {
            String alias = Integer.toString(i);
            keyStore.setCertificateEntry(alias, cert);
            i++;
        }
        X509ExtendedTrustManager newDelegateManager = createDelegateTrustManager(keyStore);
        this.delegateManager = newDelegateManager;
    }

    private static X509ExtendedTrustManager createDelegateTrustManager(KeyStore keyStore) throws NoSuchAlgorithmException, KeyStoreException, CertificateException {
        TrustManagerFactory tmf = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm());
        tmf.init(keyStore);
        X509ExtendedTrustManager delegateManager = null;
        TrustManager[] tms = tmf.getTrustManagers();
        int j = 0;
        while (true) {
            if (j >= tms.length) {
                break;
            }
            if (!(tms[j] instanceof X509ExtendedTrustManager)) {
                j++;
            } else {
                delegateManager = (X509ExtendedTrustManager) tms[j];
                break;
            }
        }
        if (delegateManager == null) {
            throw new CertificateException("Failed to find X509ExtendedTrustManager with default TrustManager algorithm " + TrustManagerFactory.getDefaultAlgorithm());
        }
        return delegateManager;
    }

    private void checkTrusted(X509Certificate[] chain, String authType, SSLEngine sslEngine, Socket socket, boolean checkingServer) throws CertificateException {
        if (chain == null || chain.length == 0) {
            throw new IllegalArgumentException("Want certificate verification but got null or empty certificates");
        }
        if (sslEngine == null && socket == null) {
            throw new CertificateException("Not enough information to validate peer. SSLEngine or Socket required.");
        }
        if (this.verification != Verification.INSECURELY_SKIP_ALL_VERIFICATION) {
            X509ExtendedTrustManager currentDelegateManager = this.delegateManager;
            if (currentDelegateManager == null) {
                throw new CertificateException("No trust roots configured");
            }
            if (checkingServer) {
                String algorithm = this.verification == Verification.CERTIFICATE_AND_HOST_NAME_VERIFICATION ? "HTTPS" : "";
                if (sslEngine != null) {
                    SSLParameters sslParams = sslEngine.getSSLParameters();
                    sslParams.setEndpointIdentificationAlgorithm(algorithm);
                    sslEngine.setSSLParameters(sslParams);
                    currentDelegateManager.checkServerTrusted(chain, authType, sslEngine);
                } else {
                    if (!(socket instanceof SSLSocket)) {
                        throw new CertificateException("socket is not a type of SSLSocket");
                    }
                    SSLSocket sslSocket = (SSLSocket) socket;
                    SSLParameters sslParams2 = sslSocket.getSSLParameters();
                    sslParams2.setEndpointIdentificationAlgorithm(algorithm);
                    sslSocket.setSSLParameters(sslParams2);
                    currentDelegateManager.checkServerTrusted(chain, authType, sslSocket);
                }
            } else {
                currentDelegateManager.checkClientTrusted(chain, authType, sslEngine);
            }
        }
        if (this.socketAndEnginePeerVerifier != null) {
            if (sslEngine != null) {
                this.socketAndEnginePeerVerifier.verifyPeerCertificate(chain, authType, sslEngine);
            } else {
                this.socketAndEnginePeerVerifier.verifyPeerCertificate(chain, authType, socket);
            }
        }
    }

    public Closeable updateTrustCredentialsFromFile(File trustCertFile, long period, TimeUnit unit, ScheduledExecutorService executor) throws GeneralSecurityException, IOException {
        long updatedTime = readAndUpdate(trustCertFile, 0L);
        if (updatedTime == 0) {
            throw new GeneralSecurityException("Files were unmodified before their initial update. Probably a bug.");
        }
        final ScheduledFuture<?> future = executor.scheduleWithFixedDelay(new LoadFilePathExecution(trustCertFile), period, period, unit);
        return new Closeable() { // from class: io.grpc.util.AdvancedTlsX509TrustManager.1
            @Override // io.grpc.util.AdvancedTlsX509TrustManager.Closeable, java.io.Closeable, java.lang.AutoCloseable
            public void close() {
                future.cancel(false);
            }
        };
    }

    private class LoadFilePathExecution implements Runnable {
        long currentTime = 0;
        File file;

        public LoadFilePathExecution(File file) {
            this.file = file;
        }

        @Override // java.lang.Runnable
        public void run() {
            try {
                this.currentTime = AdvancedTlsX509TrustManager.this.readAndUpdate(this.file, this.currentTime);
            } catch (IOException | GeneralSecurityException e) {
                AdvancedTlsX509TrustManager.log.log(Level.SEVERE, "Failed refreshing trust CAs from file. Using previous CAs", (Throwable) e);
            }
        }
    }

    public void updateTrustCredentialsFromFile(File trustCertFile) throws GeneralSecurityException, IOException {
        long updatedTime = readAndUpdate(trustCertFile, 0L);
        if (updatedTime == 0) {
            throw new GeneralSecurityException("Files were unmodified before their initial update. Probably a bug.");
        }
    }

    /* JADX INFO: Access modifiers changed from: private */
    public long readAndUpdate(File trustCertFile, long oldTime) throws GeneralSecurityException, IOException {
        long newTime = trustCertFile.lastModified();
        if (newTime == oldTime) {
            return oldTime;
        }
        FileInputStream inputStream = new FileInputStream(trustCertFile);
        try {
            X509Certificate[] certificates = CertificateUtils.getX509Certificates(inputStream);
            updateTrustCredentials(certificates);
            return newTime;
        } finally {
            inputStream.close();
        }
    }

    public static Builder newBuilder() {
        return new Builder();
    }

    public static final class Builder {
        private SslSocketAndEnginePeerVerifier socketAndEnginePeerVerifier;
        private Verification verification;

        private Builder() {
            this.verification = Verification.CERTIFICATE_AND_HOST_NAME_VERIFICATION;
        }

        public Builder setVerification(Verification verification) {
            this.verification = verification;
            return this;
        }

        public Builder setSslSocketAndEnginePeerVerifier(SslSocketAndEnginePeerVerifier verifier) {
            this.socketAndEnginePeerVerifier = verifier;
            return this;
        }

        public AdvancedTlsX509TrustManager build() throws CertificateException {
            return new AdvancedTlsX509TrustManager(this.verification, this.socketAndEnginePeerVerifier);
        }
    }
}
