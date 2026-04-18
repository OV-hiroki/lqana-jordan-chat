package com.google.android.gms.common.api.internal;

/* JADX INFO: compiled from: com.google.android.gms:play-services-base@@18.0.1 */
/* JADX INFO: loaded from: classes.dex */
final class zaq extends ThreadLocal<Boolean> {
    zaq() {
    }

    @Override // java.lang.ThreadLocal
    protected final /* synthetic */ Boolean initialValue() {
        return false;
    }
}
