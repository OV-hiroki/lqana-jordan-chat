package io.grpc.internal;

import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.logging.Level;
import java.util.logging.Logger;

/* JADX INFO: loaded from: classes8.dex */
public final class ReflectionLongAdderCounter implements LongCounter {
    private static final Method addMethod;
    private static final Constructor<?> defaultConstructor;
    private static final RuntimeException initializationException;
    private static final Logger logger = Logger.getLogger(ReflectionLongAdderCounter.class.getName());
    private static final Object[] one;
    private static final Method sumMethod;
    private final Object instance;

    static {
        Constructor<?> defaultConstructorLookup = null;
        Method addMethodLookup = null;
        Method sumMethodLookup = null;
        Throwable caught = null;
        try {
            Class<?> klass = Class.forName("java.util.concurrent.atomic.LongAdder");
            int i = 0;
            addMethodLookup = klass.getMethod("add", Long.TYPE);
            sumMethodLookup = klass.getMethod("sum", new Class[0]);
            Constructor<?>[] constructors = klass.getConstructors();
            int length = constructors.length;
            while (true) {
                if (i >= length) {
                    break;
                }
                Constructor<?> ctor = constructors[i];
                if (ctor.getParameterTypes().length != 0) {
                    i++;
                } else {
                    defaultConstructorLookup = ctor;
                    break;
                }
            }
        } catch (Throwable e) {
            logger.log(Level.FINE, "LongAdder can not be found via reflection, this is normal for JDK7 and below", e);
            caught = e;
        }
        if (caught == null && defaultConstructorLookup != null) {
            defaultConstructor = defaultConstructorLookup;
            addMethod = addMethodLookup;
            sumMethod = sumMethodLookup;
            initializationException = null;
        } else {
            defaultConstructor = null;
            addMethod = null;
            sumMethod = null;
            initializationException = new RuntimeException(caught);
        }
        one = new Object[]{1L};
    }

    ReflectionLongAdderCounter() {
        if (initializationException != null) {
            throw initializationException;
        }
        try {
            this.instance = defaultConstructor.newInstance(new Object[0]);
        } catch (IllegalAccessException e) {
            throw new RuntimeException(e);
        } catch (InstantiationException e2) {
            throw new RuntimeException(e2);
        } catch (InvocationTargetException e3) {
            throw new RuntimeException(e3);
        }
    }

    static boolean isAvailable() {
        return initializationException == null;
    }

    @Override // io.grpc.internal.LongCounter
    public void add(long delta) {
        try {
            addMethod.invoke(this.instance, delta == 1 ? one : new Object[]{Long.valueOf(delta)});
        } catch (IllegalAccessException e) {
            throw new RuntimeException(e);
        } catch (InvocationTargetException e2) {
            throw new RuntimeException(e2);
        }
    }

    @Override // io.grpc.internal.LongCounter
    public long value() {
        try {
            return ((Long) sumMethod.invoke(this.instance, new Object[0])).longValue();
        } catch (IllegalAccessException e) {
            throw new RuntimeException();
        } catch (InvocationTargetException e2) {
            throw new RuntimeException();
        }
    }
}
