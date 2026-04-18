package io.grpc.internal;

/* JADX INFO: loaded from: classes8.dex */
public interface ObjectPool<T> {
    T getObject();

    T returnObject(Object obj);
}
