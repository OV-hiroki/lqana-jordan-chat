package com.google.firebase.firestore.util;

import android.util.Log;
import com.google.firebase.firestore.BuildConfig;

/* JADX INFO: loaded from: classes.dex */
public class Logger {
    private static Level logLevel = Level.WARN;

    public enum Level {
        DEBUG,
        WARN,
        NONE
    }

    public static void setLogLevel(Level level) {
        logLevel = level;
    }

    public static boolean isDebugEnabled() {
        return logLevel.ordinal() >= Level.DEBUG.ordinal();
    }

    private static void doLog(Level level, String tag, String toLog, Object... values) {
        if (level.ordinal() >= logLevel.ordinal()) {
            String value = String.format("(%s) [%s]: ", BuildConfig.VERSION_NAME, tag) + String.format(toLog, values);
            switch (level) {
                case DEBUG:
                    Log.i("Firestore", value);
                    return;
                case WARN:
                    Log.w("Firestore", value);
                    return;
                case NONE:
                    throw new IllegalStateException("Trying to log something on level NONE");
                default:
                    return;
            }
        }
    }

    public static void warn(String tag, String toLog, Object... values) {
        doLog(Level.WARN, tag, toLog, values);
    }

    public static void debug(String tag, String toLog, Object... values) {
        doLog(Level.DEBUG, tag, toLog, values);
    }
}
