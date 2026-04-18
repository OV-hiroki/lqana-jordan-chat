package com.google.firebase.firestore.util;

import javax.annotation.Nullable;

/* JADX INFO: loaded from: classes.dex */
public interface Function<F, T> {
    @Nullable
    T apply(@Nullable F f);

    boolean equals(@Nullable Object obj);
}
