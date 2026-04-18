package io.grpc.internal;

import io.grpc.Compressor;
import java.io.InputStream;

/* JADX INFO: loaded from: classes8.dex */
public interface Stream {
    void flush();

    boolean isReady();

    void optimizeForDirectExecutor();

    void request(int i);

    void setCompressor(Compressor compressor);

    void setMessageCompression(boolean z);

    void writeMessage(InputStream inputStream);
}
