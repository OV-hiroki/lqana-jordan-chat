package com.google.firebase.firestore.index;

import java.math.RoundingMode;

/* JADX INFO: loaded from: classes.dex */
public final class IntMath {
    public static int divide(int p, int q, RoundingMode mode) {
        if (q == 0) {
            throw new ArithmeticException("/ by zero");
        }
        int div = p / q;
        int rem = p - (q * div);
        if (rem == 0) {
            return div;
        }
        boolean increment = true;
        int signum = ((p ^ q) >> 31) | 1;
        switch (AnonymousClass1.$SwitchMap$java$math$RoundingMode[mode.ordinal()]) {
            case 1:
            case 2:
                increment = false;
                break;
            case 3:
                increment = true;
                break;
            case 4:
                if (signum <= 0) {
                    increment = false;
                }
                break;
            case 5:
                if (signum >= 0) {
                    increment = false;
                }
                break;
            case 6:
            case 7:
            case 8:
                int absRem = Math.abs(rem);
                int cmpRemToHalfDivisor = absRem - (Math.abs(q) - absRem);
                if (cmpRemToHalfDivisor == 0) {
                    if (mode != RoundingMode.HALF_UP) {
                        if (!((mode == RoundingMode.HALF_EVEN) & ((div & 1) != 0))) {
                            increment = false;
                        }
                    }
                } else if (cmpRemToHalfDivisor <= 0) {
                    increment = false;
                }
                break;
            default:
                throw new AssertionError();
        }
        return increment ? div + signum : div;
    }

    /* JADX INFO: renamed from: com.google.firebase.firestore.index.IntMath$1, reason: invalid class name */
    static /* synthetic */ class AnonymousClass1 {
        static final /* synthetic */ int[] $SwitchMap$java$math$RoundingMode = new int[RoundingMode.values().length];

        static {
            try {
                $SwitchMap$java$math$RoundingMode[RoundingMode.UNNECESSARY.ordinal()] = 1;
            } catch (NoSuchFieldError e) {
            }
            try {
                $SwitchMap$java$math$RoundingMode[RoundingMode.DOWN.ordinal()] = 2;
            } catch (NoSuchFieldError e2) {
            }
            try {
                $SwitchMap$java$math$RoundingMode[RoundingMode.UP.ordinal()] = 3;
            } catch (NoSuchFieldError e3) {
            }
            try {
                $SwitchMap$java$math$RoundingMode[RoundingMode.CEILING.ordinal()] = 4;
            } catch (NoSuchFieldError e4) {
            }
            try {
                $SwitchMap$java$math$RoundingMode[RoundingMode.FLOOR.ordinal()] = 5;
            } catch (NoSuchFieldError e5) {
            }
            try {
                $SwitchMap$java$math$RoundingMode[RoundingMode.HALF_EVEN.ordinal()] = 6;
            } catch (NoSuchFieldError e6) {
            }
            try {
                $SwitchMap$java$math$RoundingMode[RoundingMode.HALF_DOWN.ordinal()] = 7;
            } catch (NoSuchFieldError e7) {
            }
            try {
                $SwitchMap$java$math$RoundingMode[RoundingMode.HALF_UP.ordinal()] = 8;
            } catch (NoSuchFieldError e8) {
            }
        }
    }

    private IntMath() {
    }
}
