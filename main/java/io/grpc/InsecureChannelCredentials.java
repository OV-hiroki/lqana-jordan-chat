package io.grpc;

/* JADX INFO: loaded from: classes8.dex */
public final class InsecureChannelCredentials extends ChannelCredentials {
    public static ChannelCredentials create() {
        return new InsecureChannelCredentials();
    }

    private InsecureChannelCredentials() {
    }

    @Override // io.grpc.ChannelCredentials
    public ChannelCredentials withoutBearerTokens() {
        return this;
    }
}
