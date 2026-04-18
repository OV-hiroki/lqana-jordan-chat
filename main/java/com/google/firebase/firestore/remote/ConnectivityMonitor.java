package com.google.firebase.firestore.remote;

import com.google.firebase.firestore.util.Consumer;

/* JADX INFO: loaded from: classes.dex */
public interface ConnectivityMonitor {

    public enum NetworkStatus {
        UNREACHABLE,
        REACHABLE
    }

    void addCallback(Consumer<NetworkStatus> consumer);

    void shutdown();
}
