package io.grpc;

import java.io.IOException;
import java.io.InputStream;

/* JADX INFO: loaded from: classes8.dex */
public interface Decompressor {
    InputStream decompress(InputStream inputStream) throws IOException;

    String getMessageEncoding();
}
