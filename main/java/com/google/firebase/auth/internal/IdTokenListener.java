package com.google.firebase.auth.internal;

import com.google.firebase.internal.InternalTokenResult;

/* JADX INFO: compiled from: com.google.firebase:firebase-auth-interop@@19.0.2 */
/* JADX INFO: loaded from: classes.dex */
public interface IdTokenListener {
    void onIdTokenChanged(InternalTokenResult internalTokenResult);
}
