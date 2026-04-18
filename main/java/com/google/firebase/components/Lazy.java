package com.google.firebase.components;

import com.google.firebase.inject.Provider;

/* JADX INFO: loaded from: classes.dex */
public class Lazy<T> implements Provider<T> {
    private static final Object UNINITIALIZED = new Object();
    private volatile Object instance;
    private volatile Provider<T> provider;

    Lazy(T instance) {
        this.instance = UNINITIALIZED;
        this.instance = instance;
    }

    public Lazy(Provider<T> provider) {
        this.instance = UNINITIALIZED;
        this.provider = provider;
    }

    @Override // com.google.firebase.inject.Provider
    public T get() {
        Object obj = this.instance;
        if (obj == UNINITIALIZED) {
            synchronized (this) {
                obj = this.instance;
                if (obj == UNINITIALIZED) {
                    obj = this.provider.get();
                    this.instance = obj;
                    this.provider = null;
                }
            }
        }
        return (T) obj;
    }

    boolean isInitialized() {
        return this.instance != UNINITIALIZED;
    }
}
