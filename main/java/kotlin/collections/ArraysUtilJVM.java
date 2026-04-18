package kotlin.collections;

import java.util.Arrays;
import java.util.List;

/* JADX INFO: loaded from: classes8.dex */
class ArraysUtilJVM {
    ArraysUtilJVM() {
    }

    static <T> List<T> asList(T[] array) {
        return Arrays.asList(array);
    }
}
