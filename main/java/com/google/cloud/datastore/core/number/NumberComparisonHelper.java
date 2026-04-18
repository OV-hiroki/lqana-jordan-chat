package com.google.cloud.datastore.core.number;

/* JADX INFO: loaded from: classes.dex */
public final class NumberComparisonHelper {
    public static final double LONG_EXCLUSIVE_UPPER_BOUND_AS_DOUBLE = 9.223372036854776E18d;
    public static final double LONG_INCLUSIVE_LOWER_BOUND_AS_DOUBLE = -9.223372036854776E18d;
    public static final long MAX_SAFE_LONG = 9007199254740992L;
    public static final long MIN_SAFE_LONG = -9007199254740992L;

    public static int firestoreCompareDoubleWithLong(double doubleValue, long longValue) {
        if (Double.isNaN(doubleValue) || doubleValue < -9.223372036854776E18d) {
            return -1;
        }
        if (doubleValue >= 9.223372036854776E18d) {
            return 1;
        }
        long doubleAsLong = (long) doubleValue;
        int cmp = compareLongs(doubleAsLong, longValue);
        if (cmp != 0) {
            return cmp;
        }
        double longAsDouble = longValue;
        return firestoreCompareDoubles(doubleValue, longAsDouble);
    }

    public static int compareLongs(long leftLong, long rightLong) {
        if (leftLong < rightLong) {
            return -1;
        }
        if (leftLong > rightLong) {
            return 1;
        }
        return 0;
    }

    public static int firestoreCompareDoubles(double leftDouble, double rightDouble) {
        if (leftDouble < rightDouble) {
            return -1;
        }
        if (leftDouble > rightDouble) {
            return 1;
        }
        if (leftDouble == rightDouble) {
            return 0;
        }
        if (Double.isNaN(rightDouble)) {
            return !Double.isNaN(leftDouble) ? 1 : 0;
        }
        return -1;
    }

    private NumberComparisonHelper() {
    }
}
