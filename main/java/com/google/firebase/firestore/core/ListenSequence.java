package com.google.firebase.firestore.core;

/* JADX INFO: loaded from: classes.dex */
public class ListenSequence {
    public static final long INVALID = -1;
    private long previousSequenceNumber;

    public ListenSequence(long startAfter) {
        this.previousSequenceNumber = startAfter;
    }

    public long next() {
        long j = this.previousSequenceNumber + 1;
        this.previousSequenceNumber = j;
        return j;
    }
}
