package com.google.firebase.firestore.bundle;

import com.google.firebase.firestore.model.SnapshotVersion;

/* JADX INFO: loaded from: classes.dex */
public class BundleMetadata implements BundleElement {
    private final String bundleId;
    private final SnapshotVersion createTime;
    private final int schemaVersion;
    private final long totalBytes;
    private final int totalDocuments;

    public BundleMetadata(String bundleId, int schemaVersion, SnapshotVersion createTime, int totalDocuments, long totalBytes) {
        this.bundleId = bundleId;
        this.schemaVersion = schemaVersion;
        this.createTime = createTime;
        this.totalDocuments = totalDocuments;
        this.totalBytes = totalBytes;
    }

    public String getBundleId() {
        return this.bundleId;
    }

    public int getSchemaVersion() {
        return this.schemaVersion;
    }

    public SnapshotVersion getCreateTime() {
        return this.createTime;
    }

    public int getTotalDocuments() {
        return this.totalDocuments;
    }

    public long getTotalBytes() {
        return this.totalBytes;
    }

    public boolean equals(Object o) {
        if (this == o) {
            return true;
        }
        if (o == null || getClass() != o.getClass()) {
            return false;
        }
        BundleMetadata that = (BundleMetadata) o;
        if (this.schemaVersion != that.schemaVersion || this.totalDocuments != that.totalDocuments || this.totalBytes != that.totalBytes || !this.bundleId.equals(that.bundleId)) {
            return false;
        }
        return this.createTime.equals(that.createTime);
    }

    public int hashCode() {
        int result = this.bundleId.hashCode();
        return (((((((result * 31) + this.schemaVersion) * 31) + this.totalDocuments) * 31) + ((int) (this.totalBytes ^ (this.totalBytes >>> 32)))) * 31) + this.createTime.hashCode();
    }
}
