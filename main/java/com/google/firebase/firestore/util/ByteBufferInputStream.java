package com.google.firebase.firestore.util;

import java.io.IOException;
import java.io.InputStream;
import java.nio.ByteBuffer;

/* JADX INFO: loaded from: classes.dex */
public class ByteBufferInputStream extends InputStream {
    ByteBuffer buffer;

    public ByteBufferInputStream(ByteBuffer buf) {
        this.buffer = buf;
    }

    @Override // java.io.InputStream
    public int available() throws IOException {
        return this.buffer.remaining();
    }

    @Override // java.io.InputStream
    public int read() {
        if (!this.buffer.hasRemaining()) {
            return -1;
        }
        return this.buffer.get() & 255;
    }

    @Override // java.io.InputStream
    public int read(byte[] b, int off, int len) throws IOException {
        if (!this.buffer.hasRemaining()) {
            return -1;
        }
        int len2 = Math.min(len, this.buffer.remaining());
        this.buffer.get(b, off, len2);
        return len2;
    }
}
