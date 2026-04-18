package com.google.firebase.components;

import com.google.firebase.inject.Deferred;
import com.google.firebase.inject.Provider;
import java.util.Set;

/* JADX INFO: loaded from: classes.dex */
public interface ComponentContainer {
    <T> Deferred<T> getDeferred(Qualified<T> qualified);

    <T> Provider<T> getProvider(Qualified<T> qualified);

    <T> Provider<Set<T>> setOfProvider(Qualified<T> qualified);

    default <T> T get(Class<T> cls) {
        return (T) get(Qualified.unqualified(cls));
    }

    default <T> Provider<T> getProvider(Class<T> anInterface) {
        return getProvider(Qualified.unqualified(anInterface));
    }

    default <T> Deferred<T> getDeferred(Class<T> anInterface) {
        return getDeferred(Qualified.unqualified(anInterface));
    }

    default <T> Set<T> setOf(Class<T> anInterface) {
        return setOf(Qualified.unqualified(anInterface));
    }

    default <T> Provider<Set<T>> setOfProvider(Class<T> anInterface) {
        return setOfProvider(Qualified.unqualified(anInterface));
    }

    default <T> T get(Qualified<T> anInterface) {
        Provider<T> provider = getProvider(anInterface);
        if (provider == null) {
            return null;
        }
        return provider.get();
    }

    default <T> Set<T> setOf(Qualified<T> anInterface) {
        return setOfProvider(anInterface).get();
    }
}
