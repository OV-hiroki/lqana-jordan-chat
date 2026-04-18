package io.grpc.internal;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.security.Provider;

/* JADX INFO: loaded from: classes8.dex */
public final class ConscryptLoader {
    private static final Method IS_CONSCRYPT_METHOD;
    private static final Method NEW_PROVIDER_METHOD;

    static {
        Method newProvider;
        Method isConscrypt;
        try {
            Class<?> conscryptClass = Class.forName("org.conscrypt.Conscrypt");
            newProvider = conscryptClass.getMethod("newProvider", new Class[0]);
            isConscrypt = conscryptClass.getMethod("isConscrypt", Provider.class);
        } catch (ClassNotFoundException e) {
            newProvider = null;
            isConscrypt = null;
        } catch (NoSuchMethodException ex) {
            throw new AssertionError(ex);
        }
        NEW_PROVIDER_METHOD = newProvider;
        IS_CONSCRYPT_METHOD = isConscrypt;
    }

    public static boolean isPresent() {
        return NEW_PROVIDER_METHOD != null;
    }

    public static boolean isConscrypt(Provider provider) {
        if (!isPresent()) {
            return false;
        }
        try {
            return ((Boolean) IS_CONSCRYPT_METHOD.invoke(null, provider)).booleanValue();
        } catch (IllegalAccessException ex) {
            throw new AssertionError(ex);
        } catch (InvocationTargetException ex2) {
            throw new AssertionError(ex2);
        }
    }

    public static Provider newProvider() throws Throwable {
        if (!isPresent()) {
            Class.forName("org.conscrypt.Conscrypt");
            throw new AssertionError("Unexpected failure referencing Conscrypt class");
        }
        return (Provider) NEW_PROVIDER_METHOD.invoke(null, new Object[0]);
    }
}
