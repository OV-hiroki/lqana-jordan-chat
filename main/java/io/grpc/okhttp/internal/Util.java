package io.grpc.okhttp.internal;

import java.lang.reflect.Array;
import java.nio.charset.Charset;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

/* JADX INFO: loaded from: classes8.dex */
public final class Util {
    public static final String[] EMPTY_STRING_ARRAY = new String[0];
    public static final Charset UTF_8 = Charset.forName("UTF-8");

    private Util() {
    }

    public static boolean equal(Object a, Object b) {
        return a == b || (a != null && a.equals(b));
    }

    public static <T> List<T> immutableList(T[] elements) {
        return Collections.unmodifiableList(Arrays.asList((Object[]) elements.clone()));
    }

    /* JADX WARN: Multi-variable type inference failed */
    public static <T> T[] intersect(Class<T> cls, T[] tArr, T[] tArr2) {
        List listIntersect = intersect(tArr, tArr2);
        return (T[]) listIntersect.toArray((Object[]) Array.newInstance((Class<?>) cls, listIntersect.size()));
    }

    private static <T> List<T> intersect(T[] first, T[] second) {
        List<T> result = new ArrayList<>();
        for (T a : first) {
            int length = second.length;
            int i = 0;
            while (true) {
                if (i < length) {
                    T b = second[i];
                    if (!a.equals(b)) {
                        i++;
                    } else {
                        result.add(b);
                        break;
                    }
                }
            }
        }
        return result;
    }
}
