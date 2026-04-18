package io.grpc.internal;

import java.nio.ByteBuffer;

/* JADX INFO: loaded from: classes8.dex */
public abstract class AbstractReadableBuffer implements ReadableBuffer {
    @Override // io.grpc.internal.ReadableBuffer
    public final int readInt() {
        checkReadable(4);
        int b1 = readUnsignedByte();
        int b2 = readUnsignedByte();
        int b3 = readUnsignedByte();
        int b4 = readUnsignedByte();
        return (b1 << 24) | (b2 << 16) | (b3 << 8) | b4;
    }

    @Override // io.grpc.internal.ReadableBuffer
    public boolean hasArray() {
        return false;
    }

    @Override // io.grpc.internal.ReadableBuffer
    public byte[] array() {
        throw new UnsupportedOperationException();
    }

    @Override // io.grpc.internal.ReadableBuffer
    public int arrayOffset() {
        throw new UnsupportedOperationException();
    }

    @Override // io.grpc.internal.ReadableBuffer
    public boolean markSupported() {
        return false;
    }

    @Override // io.grpc.internal.ReadableBuffer
    public void mark() {
    }

    @Override // io.grpc.internal.ReadableBuffer
    public void reset() {
        throw new UnsupportedOperationException();
    }

    @Override // io.grpc.internal.ReadableBuffer
    public boolean byteBufferSupported() {
        return false;
    }

    @Override // io.grpc.internal.ReadableBuffer
    public ByteBuffer getByteBuffer() {
        throw new UnsupportedOperationException();
    }

    @Override // io.grpc.internal.ReadableBuffer, java.io.Closeable, java.lang.AutoCloseable
    public void close() {
    }

    protected final void checkReadable(int length) {
        if (readableBytes() < length) {
            throw new IndexOutOfBoundsException();
        }
    }
}
