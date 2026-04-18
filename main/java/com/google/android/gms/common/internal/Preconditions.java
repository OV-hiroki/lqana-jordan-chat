package com.google.android.gms.common.internal;

import android.os.Handler;
import android.os.Looper;
import android.text.TextUtils;
import org.checkerframework.checker.nullness.qual.EnsuresNonNull;

/* JADX INFO: compiled from: com.google.android.gms:play-services-basement@@18.1.0 */
/* JADX INFO: loaded from: classes.dex */
public final class Preconditions {
    private Preconditions() {
        throw new AssertionError("Uninstantiable");
    }

    public static void checkArgument(boolean expression) {
        if (!expression) {
            throw new IllegalArgumentException();
        }
    }

    public static void checkHandlerThread(Handler handler) {
        Looper looperMyLooper = Looper.myLooper();
        if (looperMyLooper != handler.getLooper()) {
            String name = looperMyLooper != null ? looperMyLooper.getThread().getName() : "null current looper";
            throw new IllegalStateException("Must be called on " + handler.getLooper().getThread().getName() + " thread, but got " + name + ".");
        }
    }

    public static void checkMainThread() {
        checkMainThread("Must be called on the main application thread");
    }

    @EnsuresNonNull({"#1"})
    public static String checkNotEmpty(String string) {
        if (TextUtils.isEmpty(string)) {
            throw new IllegalArgumentException("Given String is empty or null");
        }
        return string;
    }

    public static void checkNotMainThread() {
        checkNotMainThread("Must not be called on the main application thread");
    }

    @EnsuresNonNull({"#1"})
    public static <T> T checkNotNull(T t) {
        if (t != null) {
            return t;
        }
        throw new NullPointerException("null reference");
    }

    public static int checkNotZero(int value) {
        if (value != 0) {
            return value;
        }
        throw new IllegalArgumentException("Given Integer is zero");
    }

    public static void checkState(boolean expression) {
        if (!expression) {
            throw new IllegalStateException();
        }
    }

    public static void checkArgument(boolean expression, Object errorMessage) {
        if (!expression) {
            throw new IllegalArgumentException(String.valueOf(errorMessage));
        }
    }

    public static void checkMainThread(String errorMessage) {
        if (!com.google.android.gms.common.util.zzb.zza()) {
            throw new IllegalStateException(errorMessage);
        }
    }

    public static void checkNotMainThread(String errorMessage) {
        if (com.google.android.gms.common.util.zzb.zza()) {
            throw new IllegalStateException(errorMessage);
        }
    }

    @EnsuresNonNull({"#1"})
    public static <T> T checkNotNull(T t, Object errorMessage) {
        if (t != null) {
            return t;
        }
        throw new NullPointerException(String.valueOf(errorMessage));
    }

    public static int checkNotZero(int value, Object errorMessage) {
        if (value != 0) {
            return value;
        }
        throw new IllegalArgumentException(String.valueOf(errorMessage));
    }

    public static void checkState(boolean expression, Object errorMessage) {
        if (!expression) {
            throw new IllegalStateException(String.valueOf(errorMessage));
        }
    }

    public static void checkArgument(boolean expression, String errorMessage, Object... errorMessageArgs) {
        if (!expression) {
            throw new IllegalArgumentException(String.format(errorMessage, errorMessageArgs));
        }
    }

    @EnsuresNonNull({"#1"})
    public static String checkNotEmpty(String string, Object errorMessage) {
        if (TextUtils.isEmpty(string)) {
            throw new IllegalArgumentException(String.valueOf(errorMessage));
        }
        return string;
    }

    public static long checkNotZero(long value) {
        if (value != 0) {
            return value;
        }
        throw new IllegalArgumentException("Given Long is zero");
    }

    public static void checkState(boolean expression, String errorMessage, Object... errorMessageArgs) {
        if (!expression) {
            throw new IllegalStateException(String.format(errorMessage, errorMessageArgs));
        }
    }

    public static long checkNotZero(long value, Object errorMessage) {
        if (value != 0) {
            return value;
        }
        throw new IllegalArgumentException(String.valueOf(errorMessage));
    }

    public static void checkHandlerThread(Handler handler, String errorMessage) {
        if (Looper.myLooper() == handler.getLooper()) {
        } else {
            throw new IllegalStateException(errorMessage);
        }
    }
}
