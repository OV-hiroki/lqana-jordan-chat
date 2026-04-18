package io.grpc;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.ServiceConfigurationError;
import java.util.ServiceLoader;

/* JADX INFO: loaded from: classes8.dex */
final class ServiceProviders {

    public interface PriorityAccessor<T> {
        int getPriority(T t);

        boolean isAvailable(T t);
    }

    private ServiceProviders() {
    }

    public static <T> T load(Class<T> klass, Iterable<Class<?>> hardcoded, ClassLoader cl, PriorityAccessor<T> priorityAccessor) {
        List<T> candidates = loadAll(klass, hardcoded, cl, priorityAccessor);
        if (candidates.isEmpty()) {
            return null;
        }
        return candidates.get(0);
    }

    public static <T> List<T> loadAll(Class<T> klass, Iterable<Class<?>> hardcoded, ClassLoader cl, final PriorityAccessor<T> priorityAccessor) {
        Iterable<T> candidates;
        if (isAndroid(cl)) {
            candidates = getCandidatesViaHardCoded(klass, hardcoded);
        } else {
            candidates = getCandidatesViaServiceLoader(klass, cl);
        }
        List<T> list = new ArrayList<>();
        for (T current : candidates) {
            if (priorityAccessor.isAvailable(current)) {
                list.add(current);
            }
        }
        Collections.sort(list, Collections.reverseOrder(new Comparator<T>() { // from class: io.grpc.ServiceProviders.1
            @Override // java.util.Comparator
            public int compare(T f1, T f2) {
                int pd = priorityAccessor.getPriority(f1) - priorityAccessor.getPriority(f2);
                if (pd != 0) {
                    return pd;
                }
                return f1.getClass().getName().compareTo(f2.getClass().getName());
            }
        }));
        return Collections.unmodifiableList(list);
    }

    static boolean isAndroid(ClassLoader cl) {
        try {
            Class.forName("android.app.Application", false, cl);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    public static <T> Iterable<T> getCandidatesViaServiceLoader(Class<T> klass, ClassLoader cl) {
        Iterable<T> i = ServiceLoader.load(klass, cl);
        if (!i.iterator().hasNext()) {
            return ServiceLoader.load(klass);
        }
        return i;
    }

    static <T> Iterable<T> getCandidatesViaHardCoded(Class<T> klass, Iterable<Class<?>> hardcoded) {
        ArrayList arrayList = new ArrayList();
        for (Class<?> candidate : hardcoded) {
            Object objCreateForHardCoded = createForHardCoded(klass, candidate);
            if (objCreateForHardCoded != null) {
                arrayList.add(objCreateForHardCoded);
            }
        }
        return arrayList;
    }

    private static <T> T createForHardCoded(Class<T> cls, Class<?> cls2) {
        try {
            return (T) cls2.asSubclass(cls).getConstructor(new Class[0]).newInstance(new Object[0]);
        } catch (ClassCastException e) {
            return null;
        } catch (Throwable th) {
            throw new ServiceConfigurationError(String.format("Provider %s could not be instantiated %s", cls2.getName(), th), th);
        }
    }
}
