package io.grpc.internal;

/* JADX INFO: loaded from: classes8.dex */
public interface WritableBuffer {
    int readableBytes();

    void release();

    int writableBytes();

    void write(byte b);

    void write(byte[] bArr, int i, int i2);
}
