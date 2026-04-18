package io.grpc.stub;

/* JADX INFO: loaded from: classes8.dex */
public interface StreamObserver<V> {
    void onCompleted();

    void onError(Throwable th);

    void onNext(V v);
}
