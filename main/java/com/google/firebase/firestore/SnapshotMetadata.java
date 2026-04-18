package com.google.firebase.firestore;

/* JADX INFO: loaded from: classes.dex */
public class SnapshotMetadata {
    private final boolean hasPendingWrites;
    private final boolean isFromCache;

    SnapshotMetadata(boolean hasPendingWrites, boolean isFromCache) {
        this.hasPendingWrites = hasPendingWrites;
        this.isFromCache = isFromCache;
    }

    public boolean hasPendingWrites() {
        return this.hasPendingWrites;
    }

    public boolean isFromCache() {
        return this.isFromCache;
    }

    public boolean equals(Object obj) {
        if (this == obj) {
            return true;
        }
        if (!(obj instanceof SnapshotMetadata)) {
            return false;
        }
        SnapshotMetadata other = (SnapshotMetadata) obj;
        return this.hasPendingWrites == other.hasPendingWrites && this.isFromCache == other.isFromCache;
    }

    public int hashCode() {
        return ((this.hasPendingWrites ? 1 : 0) * 31) + (this.isFromCache ? 1 : 0);
    }

    public String toString() {
        return "SnapshotMetadata{hasPendingWrites=" + this.hasPendingWrites + ", isFromCache=" + this.isFromCache + '}';
    }
}
