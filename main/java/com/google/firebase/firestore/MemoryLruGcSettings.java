package com.google.firebase.firestore;

/* JADX INFO: loaded from: classes.dex */
public final class MemoryLruGcSettings implements MemoryGarbageCollectorSettings {
    private long sizeBytes;

    public static class Builder {
        private long sizeBytes;

        private Builder() {
            this.sizeBytes = 104857600L;
        }

        public MemoryLruGcSettings build() {
            return new MemoryLruGcSettings(this.sizeBytes);
        }

        public Builder setSizeBytes(long size) {
            this.sizeBytes = size;
            return this;
        }
    }

    private MemoryLruGcSettings(long size) {
        this.sizeBytes = size;
    }

    public static Builder newBuilder() {
        return new Builder();
    }

    public long getSizeBytes() {
        return this.sizeBytes;
    }

    public boolean equals(Object o) {
        if (this == o) {
            return true;
        }
        if (o == null || getClass() != o.getClass()) {
            return false;
        }
        MemoryLruGcSettings that = (MemoryLruGcSettings) o;
        if (this.sizeBytes == that.sizeBytes) {
            return true;
        }
        return false;
    }

    public int hashCode() {
        return (int) (this.sizeBytes ^ (this.sizeBytes >>> 32));
    }

    public String toString() {
        return "MemoryLruGcSettings{cacheSize=" + getSizeBytes() + "}";
    }
}
