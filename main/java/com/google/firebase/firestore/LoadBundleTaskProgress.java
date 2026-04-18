package com.google.firebase.firestore;

import com.google.firebase.firestore.bundle.BundleMetadata;

/* JADX INFO: loaded from: classes.dex */
public final class LoadBundleTaskProgress {
    static final LoadBundleTaskProgress INITIAL = new LoadBundleTaskProgress(0, 0, 0, 0, null, TaskState.SUCCESS);
    private final long bytesLoaded;
    private final int documentsLoaded;
    private final Exception exception;
    private final TaskState taskState;
    private final long totalBytes;
    private final int totalDocuments;

    public enum TaskState {
        ERROR,
        RUNNING,
        SUCCESS
    }

    public LoadBundleTaskProgress(int documentsLoaded, int totalDocuments, long bytesLoaded, long totalBytes, Exception exception, TaskState taskState) {
        this.documentsLoaded = documentsLoaded;
        this.totalDocuments = totalDocuments;
        this.bytesLoaded = bytesLoaded;
        this.totalBytes = totalBytes;
        this.taskState = taskState;
        this.exception = exception;
    }

    public static LoadBundleTaskProgress forInitial(BundleMetadata bundleMetadata) {
        return new LoadBundleTaskProgress(0, bundleMetadata.getTotalDocuments(), 0L, bundleMetadata.getTotalBytes(), null, TaskState.RUNNING);
    }

    public static LoadBundleTaskProgress forSuccess(BundleMetadata bundleMetadata) {
        return new LoadBundleTaskProgress(bundleMetadata.getTotalDocuments(), bundleMetadata.getTotalDocuments(), bundleMetadata.getTotalBytes(), bundleMetadata.getTotalBytes(), null, TaskState.SUCCESS);
    }

    public int getDocumentsLoaded() {
        return this.documentsLoaded;
    }

    public int getTotalDocuments() {
        return this.totalDocuments;
    }

    public long getBytesLoaded() {
        return this.bytesLoaded;
    }

    public long getTotalBytes() {
        return this.totalBytes;
    }

    public TaskState getTaskState() {
        return this.taskState;
    }

    public Exception getException() {
        return this.exception;
    }

    public boolean equals(Object o) {
        if (this == o) {
            return true;
        }
        if (o == null || getClass() != o.getClass()) {
            return false;
        }
        LoadBundleTaskProgress that = (LoadBundleTaskProgress) o;
        if (this.documentsLoaded != that.documentsLoaded || this.totalDocuments != that.totalDocuments || this.bytesLoaded != that.bytesLoaded || this.totalBytes != that.totalBytes || this.taskState != that.taskState) {
            return false;
        }
        if (this.exception != null) {
            return this.exception.equals(that.exception);
        }
        if (that.exception == null) {
            return true;
        }
        return false;
    }

    public int hashCode() {
        int result = this.documentsLoaded;
        return (((((((((result * 31) + this.totalDocuments) * 31) + ((int) (this.bytesLoaded ^ (this.bytesLoaded >>> 32)))) * 31) + ((int) (this.totalBytes ^ (this.totalBytes >>> 32)))) * 31) + this.taskState.hashCode()) * 31) + (this.exception != null ? this.exception.hashCode() : 0);
    }
}
