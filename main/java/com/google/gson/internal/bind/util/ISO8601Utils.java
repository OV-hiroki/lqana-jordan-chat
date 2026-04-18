package com.google.gson.internal.bind.util;

import java.util.Calendar;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.Locale;
import java.util.TimeZone;

/* JADX INFO: loaded from: classes8.dex */
public class ISO8601Utils {
    private static final String UTC_ID = "UTC";
    private static final TimeZone TIMEZONE_UTC = TimeZone.getTimeZone(UTC_ID);

    public static String format(Date date) {
        return format(date, false, TIMEZONE_UTC);
    }

    public static String format(Date date, boolean millis) {
        return format(date, millis, TIMEZONE_UTC);
    }

    public static String format(Date date, boolean millis, TimeZone tz) {
        Calendar calendar = new GregorianCalendar(tz, Locale.US);
        calendar.setTime(date);
        int capacity = "yyyy-MM-ddThh:mm:ss".length();
        StringBuilder formatted = new StringBuilder(capacity + (millis ? ".sss".length() : 0) + (tz.getRawOffset() == 0 ? "Z" : "+hh:mm").length());
        padInt(formatted, calendar.get(1), "yyyy".length());
        formatted.append('-');
        padInt(formatted, calendar.get(2) + 1, "MM".length());
        formatted.append('-');
        padInt(formatted, calendar.get(5), "dd".length());
        formatted.append('T');
        padInt(formatted, calendar.get(11), "hh".length());
        formatted.append(':');
        padInt(formatted, calendar.get(12), "mm".length());
        formatted.append(':');
        padInt(formatted, calendar.get(13), "ss".length());
        if (millis) {
            formatted.append('.');
            padInt(formatted, calendar.get(14), "sss".length());
        }
        int offset = tz.getOffset(calendar.getTimeInMillis());
        if (offset != 0) {
            int hours = Math.abs((offset / 60000) / 60);
            int minutes = Math.abs((offset / 60000) % 60);
            formatted.append(offset >= 0 ? '+' : '-');
            padInt(formatted, hours, "hh".length());
            formatted.append(':');
            padInt(formatted, minutes, "mm".length());
        } else {
            formatted.append('Z');
        }
        return formatted.toString();
    }

    /* JADX WARN: Removed duplicated region for block: B:112:0x021d  */
    /* JADX WARN: Removed duplicated region for block: B:113:0x021f  */
    /* JADX WARN: Removed duplicated region for block: B:116:0x023c  */
    /* JADX WARN: Removed duplicated region for block: B:118:0x0242  */
    /* JADX WARN: Removed duplicated region for block: B:23:0x0063 A[Catch: IllegalArgumentException -> 0x004e, NumberFormatException -> 0x0053, IndexOutOfBoundsException -> 0x0058, TryCatch #5 {IllegalArgumentException -> 0x004e, IndexOutOfBoundsException -> 0x0058, NumberFormatException -> 0x0053, blocks: (B:11:0x0039, B:13:0x003f, B:23:0x0063, B:25:0x0074, B:26:0x0076, B:28:0x0083, B:30:0x0088, B:32:0x008e, B:37:0x009a, B:43:0x00ad, B:45:0x00b5, B:58:0x00e6), top: B:122:0x0039 }] */
    /* JADX WARN: Removed duplicated region for block: B:55:0x00de A[Catch: IllegalArgumentException -> 0x020c, NumberFormatException -> 0x0211, IndexOutOfBoundsException -> 0x0216, TRY_LEAVE, TryCatch #4 {IndexOutOfBoundsException -> 0x0216, NumberFormatException -> 0x0211, IllegalArgumentException -> 0x020c, blocks: (B:3:0x0005, B:5:0x0017, B:6:0x0019, B:8:0x0025, B:9:0x0027, B:53:0x00d8, B:55:0x00de, B:65:0x00fa), top: B:123:0x0005 }] */
    /* JADX WARN: Removed duplicated region for block: B:93:0x01fa A[Catch: IllegalArgumentException -> 0x0206, NumberFormatException -> 0x0208, IndexOutOfBoundsException -> 0x020a, TryCatch #6 {IllegalArgumentException -> 0x0206, IndexOutOfBoundsException -> 0x020a, NumberFormatException -> 0x0208, blocks: (B:91:0x01c7, B:70:0x011d, B:74:0x013d, B:76:0x014a, B:89:0x01c2, B:79:0x0157, B:81:0x0178, B:84:0x018b, B:85:0x01b5, B:73:0x012a, B:67:0x0103, B:68:0x011a, B:93:0x01fa, B:94:0x0205), top: B:121:0x00dc }] */
    /*
        Code decompiled incorrectly, please refer to instructions dump.
        To view partially-correct code enable 'Show inconsistent code' option in preferences
    */
    public static java.util.Date parse(java.lang.String r22, java.text.ParsePosition r23) throws java.text.ParseException {
        /*
            Method dump skipped, instruction units count: 662
            To view this dump change 'Code comments level' option to 'DEBUG'
        */
        throw new UnsupportedOperationException("Method not decompiled: com.google.gson.internal.bind.util.ISO8601Utils.parse(java.lang.String, java.text.ParsePosition):java.util.Date");
    }

    private static boolean checkOffset(String value, int offset, char expected) {
        return offset < value.length() && value.charAt(offset) == expected;
    }

    private static int parseInt(String value, int beginIndex, int endIndex) throws NumberFormatException {
        if (beginIndex < 0 || endIndex > value.length() || beginIndex > endIndex) {
            throw new NumberFormatException(value);
        }
        int digit = beginIndex;
        int result = 0;
        if (digit < endIndex) {
            int i = digit + 1;
            int digit2 = Character.digit(value.charAt(digit), 10);
            if (digit2 < 0) {
                throw new NumberFormatException("Invalid number: " + value.substring(beginIndex, endIndex));
            }
            result = -digit2;
            digit = i;
        }
        while (digit < endIndex) {
            int i2 = digit + 1;
            int digit3 = Character.digit(value.charAt(digit), 10);
            if (digit3 < 0) {
                throw new NumberFormatException("Invalid number: " + value.substring(beginIndex, endIndex));
            }
            result = (result * 10) - digit3;
            digit = i2;
        }
        return -result;
    }

    private static void padInt(StringBuilder buffer, int value, int length) {
        String strValue = Integer.toString(value);
        for (int i = length - strValue.length(); i > 0; i--) {
            buffer.append('0');
        }
        buffer.append(strValue);
    }

    private static int indexOfNonDigit(String string, int offset) {
        for (int i = offset; i < string.length(); i++) {
            char c = string.charAt(i);
            if (c < '0' || c > '9') {
                return i;
            }
        }
        int i2 = string.length();
        return i2;
    }
}
