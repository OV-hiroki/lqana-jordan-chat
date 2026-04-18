package com.google.android.gms.common.util;

import android.os.Looper;

/* JADX INFO: compiled from: com.google.android.gms:play-services-basement@@18.1.0 */
/* JADX INFO: loaded from: classes.dex */
public final class zzb {
    public static boolean zza() {
        return Looper.getMainLooper() == Looper.myLooper();
    }
}
