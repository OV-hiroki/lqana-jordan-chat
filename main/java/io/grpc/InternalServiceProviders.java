package io.grpc;

import io.grpc.ServiceProviders;
import java.util.List;

/* JADX INFO: loaded from: classes8.dex */
public final class InternalServiceProviders {

    public interface PriorityAccessor<T> extends ServiceProviders.PriorityAccessor<T> {
    }

    private InternalServiceProviders() {
    }

    public static <T> T load(Class<T> cls, Iterable<Class<?>> iterable, ClassLoader classLoader, PriorityAccessor<T> priorityAccessor) {
        return (T) ServiceProviders.load(cls, iterable, classLoader, priorityAccessor);
    }

    public static <T> List<T> loadAll(Class<T> klass, Iterable<Class<?>> hardCodedClasses, ClassLoader classLoader, PriorityAccessor<T> priorityAccessor) {
        return ServiceProviders.loadAll(klass, hardCodedClasses, classLoader, priorityAccessor);
    }

    public static <T> Iterable<T> getCandidatesViaServiceLoader(Class<T> klass, ClassLoader cl) {
        return ServiceProviders.getCandidatesViaServiceLoader(klass, cl);
    }

    public static <T> Iterable<T> getCandidatesViaHardCoded(Class<T> klass, Iterable<Class<?>> hardcoded) {
        return ServiceProviders.getCandidatesViaHardCoded(klass, hardcoded);
    }

    public static boolean isAndroid(ClassLoader cl) {
        return ServiceProviders.isAndroid(cl);
    }
}
