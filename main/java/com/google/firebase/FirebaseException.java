package com.google.firebase;

import com.google.android.gms.common.internal.Preconditions;

/* JADX INFO: compiled from: com.google.android.gms:play-services-basement@@18.1.0 */
/* JADX INFO: loaded from: classes.dex */
public class FirebaseException extends Exception {
    @Deprecated
    protected FirebaseException() {
    }

    /* JADX WARN: 'super' call moved to the top of the method (can break code semantics) */
    public FirebaseException(String detailMessage) {
        super(detailMessage);
        Preconditions.checkNotEmpty(detailMessage, "Detail message must not be empty");
    }

    /* JADX WARN: 'super' call moved to the top of the method (can break code semantics) */
    public FirebaseException(String detailMessage, Throwable cause) {
        super(detailMessage, cause);
        Preconditions.checkNotEmpty(detailMessage, "Detail message must not be empty");
    }
}
