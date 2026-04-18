package com.google.android.gms.common.api.internal;

import android.os.Bundle;

/* JADX INFO: compiled from: com.google.android.gms:play-services-base@@18.0.1 */
/* JADX INFO: loaded from: classes.dex */
public interface ConnectionCallbacks {
    void onConnected(Bundle bundle);

    void onConnectionSuspended(int i);
}
