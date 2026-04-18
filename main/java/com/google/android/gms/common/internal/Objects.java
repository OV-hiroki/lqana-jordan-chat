package com.google.android.gms.common.internal;

import android.os.Bundle;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Set;

/* JADX INFO: compiled from: com.google.android.gms:play-services-basement@@18.1.0 */
/* JADX INFO: loaded from: classes.dex */
public final class Objects {

    /* JADX INFO: compiled from: com.google.android.gms:play-services-basement@@18.1.0 */
    public static final class ToStringHelper {
        private final List zza;
        private final Object zzb;

        /* synthetic */ ToStringHelper(Object obj, zzah zzahVar) {
            Preconditions.checkNotNull(obj);
            this.zzb = obj;
            this.zza = new ArrayList();
        }

        public ToStringHelper add(String name, Object value) {
            List list = this.zza;
            Preconditions.checkNotNull(name);
            list.add(name + "=" + String.valueOf(value));
            return this;
        }

        public String toString() {
            StringBuilder sb = new StringBuilder(100);
            sb.append(this.zzb.getClass().getSimpleName());
            sb.append('{');
            int size = this.zza.size();
            for (int i = 0; i < size; i++) {
                sb.append((String) this.zza.get(i));
                if (i < size - 1) {
                    sb.append(", ");
                }
            }
            sb.append('}');
            return sb.toString();
        }
    }

    private Objects() {
        throw new AssertionError("Uninstantiable");
    }

    public static boolean checkBundlesEquality(Bundle firstBundle, Bundle secondBundle) {
        if (firstBundle == null || secondBundle == null) {
            return firstBundle == secondBundle;
        }
        if (firstBundle.size() != secondBundle.size()) {
            return false;
        }
        Set<String> setKeySet = firstBundle.keySet();
        if (!setKeySet.containsAll(secondBundle.keySet())) {
            return false;
        }
        for (String str : setKeySet) {
            if (!equal(firstBundle.get(str), secondBundle.get(str))) {
                return false;
            }
        }
        return true;
    }

    public static boolean equal(Object a, Object b) {
        if (a != b) {
            return a != null && a.equals(b);
        }
        return true;
    }

    public static int hashCode(Object... objects) {
        return Arrays.hashCode(objects);
    }

    public static ToStringHelper toStringHelper(Object object) {
        return new ToStringHelper(object, null);
    }
}
