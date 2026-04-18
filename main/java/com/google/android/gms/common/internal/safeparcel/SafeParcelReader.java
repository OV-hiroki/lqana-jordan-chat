package com.google.android.gms.common.internal.safeparcel;

import android.app.PendingIntent;
import android.os.Bundle;
import android.os.IBinder;
import android.os.Parcel;
import android.os.Parcelable;
import android.util.SparseArray;
import android.util.SparseBooleanArray;
import android.util.SparseIntArray;
import android.util.SparseLongArray;
import androidx.core.internal.view.SupportMenu;
import java.math.BigDecimal;
import java.math.BigInteger;
import java.util.ArrayList;
import java.util.List;

/* JADX INFO: compiled from: com.google.android.gms:play-services-basement@@18.1.0 */
/* JADX INFO: loaded from: classes.dex */
public class SafeParcelReader {

    /* JADX INFO: compiled from: com.google.android.gms:play-services-basement@@18.1.0 */
    public static class ParseException extends RuntimeException {
        public ParseException(String message, Parcel p) {
            super(message + " Parcel: pos=" + p.dataPosition() + " size=" + p.dataSize());
        }
    }

    private SafeParcelReader() {
    }

    public static BigDecimal createBigDecimal(Parcel p, int header) {
        int header2 = readSize(p, header);
        int iDataPosition = p.dataPosition();
        if (header2 == 0) {
            return null;
        }
        byte[] bArrCreateByteArray = p.createByteArray();
        int i = p.readInt();
        p.setDataPosition(iDataPosition + header2);
        return new BigDecimal(new BigInteger(bArrCreateByteArray), i);
    }

    public static BigDecimal[] createBigDecimalArray(Parcel p, int header) {
        int header2 = readSize(p, header);
        int iDataPosition = p.dataPosition();
        if (header2 == 0) {
            return null;
        }
        int i = p.readInt();
        BigDecimal[] bigDecimalArr = new BigDecimal[i];
        for (int i2 = 0; i2 < i; i2++) {
            byte[] bArrCreateByteArray = p.createByteArray();
            bigDecimalArr[i2] = new BigDecimal(new BigInteger(bArrCreateByteArray), p.readInt());
        }
        p.setDataPosition(iDataPosition + header2);
        return bigDecimalArr;
    }

    public static BigInteger createBigInteger(Parcel p, int header) {
        int header2 = readSize(p, header);
        int iDataPosition = p.dataPosition();
        if (header2 == 0) {
            return null;
        }
        byte[] bArrCreateByteArray = p.createByteArray();
        p.setDataPosition(iDataPosition + header2);
        return new BigInteger(bArrCreateByteArray);
    }

    public static BigInteger[] createBigIntegerArray(Parcel p, int header) {
        int header2 = readSize(p, header);
        int iDataPosition = p.dataPosition();
        if (header2 == 0) {
            return null;
        }
        int i = p.readInt();
        BigInteger[] bigIntegerArr = new BigInteger[i];
        for (int i2 = 0; i2 < i; i2++) {
            bigIntegerArr[i2] = new BigInteger(p.createByteArray());
        }
        p.setDataPosition(iDataPosition + header2);
        return bigIntegerArr;
    }

    public static boolean[] createBooleanArray(Parcel p, int header) {
        int header2 = readSize(p, header);
        int iDataPosition = p.dataPosition();
        if (header2 == 0) {
            return null;
        }
        boolean[] zArrCreateBooleanArray = p.createBooleanArray();
        p.setDataPosition(iDataPosition + header2);
        return zArrCreateBooleanArray;
    }

    public static ArrayList<Boolean> createBooleanList(Parcel p, int header) {
        int header2 = readSize(p, header);
        int iDataPosition = p.dataPosition();
        if (header2 == 0) {
            return null;
        }
        ArrayList<Boolean> arrayList = new ArrayList<>();
        int i = p.readInt();
        for (int i2 = 0; i2 < i; i2++) {
            arrayList.add(Boolean.valueOf(p.readInt() != 0));
        }
        p.setDataPosition(iDataPosition + header2);
        return arrayList;
    }

    public static Bundle createBundle(Parcel p, int header) {
        int header2 = readSize(p, header);
        int iDataPosition = p.dataPosition();
        if (header2 == 0) {
            return null;
        }
        Bundle bundle = p.readBundle();
        p.setDataPosition(iDataPosition + header2);
        return bundle;
    }

    public static byte[] createByteArray(Parcel p, int header) {
        int header2 = readSize(p, header);
        int iDataPosition = p.dataPosition();
        if (header2 == 0) {
            return null;
        }
        byte[] bArrCreateByteArray = p.createByteArray();
        p.setDataPosition(iDataPosition + header2);
        return bArrCreateByteArray;
    }

    public static byte[][] createByteArrayArray(Parcel p, int header) {
        int header2 = readSize(p, header);
        int iDataPosition = p.dataPosition();
        if (header2 == 0) {
            return null;
        }
        int i = p.readInt();
        byte[][] bArr = new byte[i][];
        for (int i2 = 0; i2 < i; i2++) {
            bArr[i2] = p.createByteArray();
        }
        p.setDataPosition(iDataPosition + header2);
        return bArr;
    }

    public static SparseArray<byte[]> createByteArraySparseArray(Parcel p, int header) {
        int header2 = readSize(p, header);
        int iDataPosition = p.dataPosition();
        if (header2 == 0) {
            return null;
        }
        int i = p.readInt();
        SparseArray<byte[]> sparseArray = new SparseArray<>(i);
        for (int i2 = 0; i2 < i; i2++) {
            sparseArray.append(p.readInt(), p.createByteArray());
        }
        p.setDataPosition(iDataPosition + header2);
        return sparseArray;
    }

    public static char[] createCharArray(Parcel p, int header) {
        int header2 = readSize(p, header);
        int iDataPosition = p.dataPosition();
        if (header2 == 0) {
            return null;
        }
        char[] cArrCreateCharArray = p.createCharArray();
        p.setDataPosition(iDataPosition + header2);
        return cArrCreateCharArray;
    }

    public static double[] createDoubleArray(Parcel p, int header) {
        int header2 = readSize(p, header);
        int iDataPosition = p.dataPosition();
        if (header2 == 0) {
            return null;
        }
        double[] dArrCreateDoubleArray = p.createDoubleArray();
        p.setDataPosition(iDataPosition + header2);
        return dArrCreateDoubleArray;
    }

    public static ArrayList<Double> createDoubleList(Parcel p, int header) {
        int header2 = readSize(p, header);
        int iDataPosition = p.dataPosition();
        if (header2 == 0) {
            return null;
        }
        ArrayList<Double> arrayList = new ArrayList<>();
        int i = p.readInt();
        for (int i2 = 0; i2 < i; i2++) {
            arrayList.add(Double.valueOf(p.readDouble()));
        }
        p.setDataPosition(iDataPosition + header2);
        return arrayList;
    }

    public static SparseArray<Double> createDoubleSparseArray(Parcel p, int header) {
        int header2 = readSize(p, header);
        int iDataPosition = p.dataPosition();
        if (header2 == 0) {
            return null;
        }
        SparseArray<Double> sparseArray = new SparseArray<>();
        int i = p.readInt();
        for (int i2 = 0; i2 < i; i2++) {
            sparseArray.append(p.readInt(), Double.valueOf(p.readDouble()));
        }
        p.setDataPosition(iDataPosition + header2);
        return sparseArray;
    }

    public static float[] createFloatArray(Parcel p, int header) {
        int header2 = readSize(p, header);
        int iDataPosition = p.dataPosition();
        if (header2 == 0) {
            return null;
        }
        float[] fArrCreateFloatArray = p.createFloatArray();
        p.setDataPosition(iDataPosition + header2);
        return fArrCreateFloatArray;
    }

    public static ArrayList<Float> createFloatList(Parcel p, int header) {
        int header2 = readSize(p, header);
        int iDataPosition = p.dataPosition();
        if (header2 == 0) {
            return null;
        }
        ArrayList<Float> arrayList = new ArrayList<>();
        int i = p.readInt();
        for (int i2 = 0; i2 < i; i2++) {
            arrayList.add(Float.valueOf(p.readFloat()));
        }
        p.setDataPosition(iDataPosition + header2);
        return arrayList;
    }

    public static SparseArray<Float> createFloatSparseArray(Parcel p, int header) {
        int header2 = readSize(p, header);
        int iDataPosition = p.dataPosition();
        if (header2 == 0) {
            return null;
        }
        SparseArray<Float> sparseArray = new SparseArray<>();
        int i = p.readInt();
        for (int i2 = 0; i2 < i; i2++) {
            sparseArray.append(p.readInt(), Float.valueOf(p.readFloat()));
        }
        p.setDataPosition(iDataPosition + header2);
        return sparseArray;
    }

    public static IBinder[] createIBinderArray(Parcel p, int header) {
        int header2 = readSize(p, header);
        int iDataPosition = p.dataPosition();
        if (header2 == 0) {
            return null;
        }
        IBinder[] iBinderArrCreateBinderArray = p.createBinderArray();
        p.setDataPosition(iDataPosition + header2);
        return iBinderArrCreateBinderArray;
    }

    public static ArrayList<IBinder> createIBinderList(Parcel p, int header) {
        int header2 = readSize(p, header);
        int iDataPosition = p.dataPosition();
        if (header2 == 0) {
            return null;
        }
        ArrayList<IBinder> arrayListCreateBinderArrayList = p.createBinderArrayList();
        p.setDataPosition(iDataPosition + header2);
        return arrayListCreateBinderArrayList;
    }

    public static SparseArray<IBinder> createIBinderSparseArray(Parcel p, int header) {
        int header2 = readSize(p, header);
        int iDataPosition = p.dataPosition();
        if (header2 == 0) {
            return null;
        }
        int i = p.readInt();
        SparseArray<IBinder> sparseArray = new SparseArray<>(i);
        for (int i2 = 0; i2 < i; i2++) {
            sparseArray.append(p.readInt(), p.readStrongBinder());
        }
        p.setDataPosition(iDataPosition + header2);
        return sparseArray;
    }

    public static int[] createIntArray(Parcel p, int header) {
        int header2 = readSize(p, header);
        int iDataPosition = p.dataPosition();
        if (header2 == 0) {
            return null;
        }
        int[] iArrCreateIntArray = p.createIntArray();
        p.setDataPosition(iDataPosition + header2);
        return iArrCreateIntArray;
    }

    public static ArrayList<Integer> createIntegerList(Parcel p, int header) {
        int header2 = readSize(p, header);
        int iDataPosition = p.dataPosition();
        if (header2 == 0) {
            return null;
        }
        ArrayList<Integer> arrayList = new ArrayList<>();
        int i = p.readInt();
        for (int i2 = 0; i2 < i; i2++) {
            arrayList.add(Integer.valueOf(p.readInt()));
        }
        p.setDataPosition(iDataPosition + header2);
        return arrayList;
    }

    public static long[] createLongArray(Parcel p, int header) {
        int header2 = readSize(p, header);
        int iDataPosition = p.dataPosition();
        if (header2 == 0) {
            return null;
        }
        long[] jArrCreateLongArray = p.createLongArray();
        p.setDataPosition(iDataPosition + header2);
        return jArrCreateLongArray;
    }

    public static ArrayList<Long> createLongList(Parcel p, int header) {
        int header2 = readSize(p, header);
        int iDataPosition = p.dataPosition();
        if (header2 == 0) {
            return null;
        }
        ArrayList<Long> arrayList = new ArrayList<>();
        int i = p.readInt();
        for (int i2 = 0; i2 < i; i2++) {
            arrayList.add(Long.valueOf(p.readLong()));
        }
        p.setDataPosition(iDataPosition + header2);
        return arrayList;
    }

    public static Parcel createParcel(Parcel p, int header) {
        int header2 = readSize(p, header);
        int iDataPosition = p.dataPosition();
        if (header2 == 0) {
            return null;
        }
        Parcel parcelObtain = Parcel.obtain();
        parcelObtain.appendFrom(p, iDataPosition, header2);
        p.setDataPosition(iDataPosition + header2);
        return parcelObtain;
    }

    public static Parcel[] createParcelArray(Parcel p, int header) {
        int header2 = readSize(p, header);
        int iDataPosition = p.dataPosition();
        if (header2 == 0) {
            return null;
        }
        int i = p.readInt();
        Parcel[] parcelArr = new Parcel[i];
        for (int i2 = 0; i2 < i; i2++) {
            int i3 = p.readInt();
            if (i3 != 0) {
                int iDataPosition2 = p.dataPosition();
                Parcel parcelObtain = Parcel.obtain();
                parcelObtain.appendFrom(p, iDataPosition2, i3);
                parcelArr[i2] = parcelObtain;
                p.setDataPosition(iDataPosition2 + i3);
            } else {
                parcelArr[i2] = null;
            }
        }
        p.setDataPosition(iDataPosition + header2);
        return parcelArr;
    }

    public static ArrayList<Parcel> createParcelList(Parcel p, int header) {
        int header2 = readSize(p, header);
        int iDataPosition = p.dataPosition();
        if (header2 == 0) {
            return null;
        }
        int i = p.readInt();
        ArrayList<Parcel> arrayList = new ArrayList<>();
        for (int i2 = 0; i2 < i; i2++) {
            int i3 = p.readInt();
            if (i3 != 0) {
                int iDataPosition2 = p.dataPosition();
                Parcel parcelObtain = Parcel.obtain();
                parcelObtain.appendFrom(p, iDataPosition2, i3);
                arrayList.add(parcelObtain);
                p.setDataPosition(iDataPosition2 + i3);
            } else {
                arrayList.add(null);
            }
        }
        p.setDataPosition(iDataPosition + header2);
        return arrayList;
    }

    public static SparseArray<Parcel> createParcelSparseArray(Parcel p, int header) {
        int header2 = readSize(p, header);
        int iDataPosition = p.dataPosition();
        if (header2 == 0) {
            return null;
        }
        int i = p.readInt();
        SparseArray<Parcel> sparseArray = new SparseArray<>();
        for (int i2 = 0; i2 < i; i2++) {
            int i3 = p.readInt();
            int i4 = p.readInt();
            if (i4 != 0) {
                int iDataPosition2 = p.dataPosition();
                Parcel parcelObtain = Parcel.obtain();
                parcelObtain.appendFrom(p, iDataPosition2, i4);
                sparseArray.append(i3, parcelObtain);
                p.setDataPosition(iDataPosition2 + i4);
            } else {
                sparseArray.append(i3, null);
            }
        }
        p.setDataPosition(iDataPosition + header2);
        return sparseArray;
    }

    public static <T extends Parcelable> T createParcelable(Parcel p, int header, Parcelable.Creator<T> creator) {
        int header2 = readSize(p, header);
        int iDataPosition = p.dataPosition();
        if (header2 == 0) {
            return null;
        }
        T tCreateFromParcel = creator.createFromParcel(p);
        p.setDataPosition(iDataPosition + header2);
        return tCreateFromParcel;
    }

    public static SparseBooleanArray createSparseBooleanArray(Parcel p, int header) {
        int header2 = readSize(p, header);
        int iDataPosition = p.dataPosition();
        if (header2 == 0) {
            return null;
        }
        SparseBooleanArray sparseBooleanArray = p.readSparseBooleanArray();
        p.setDataPosition(iDataPosition + header2);
        return sparseBooleanArray;
    }

    public static SparseIntArray createSparseIntArray(Parcel p, int header) {
        int header2 = readSize(p, header);
        int iDataPosition = p.dataPosition();
        if (header2 == 0) {
            return null;
        }
        SparseIntArray sparseIntArray = new SparseIntArray();
        int i = p.readInt();
        for (int i2 = 0; i2 < i; i2++) {
            sparseIntArray.append(p.readInt(), p.readInt());
        }
        p.setDataPosition(iDataPosition + header2);
        return sparseIntArray;
    }

    public static SparseLongArray createSparseLongArray(Parcel p, int header) {
        int header2 = readSize(p, header);
        int iDataPosition = p.dataPosition();
        if (header2 == 0) {
            return null;
        }
        SparseLongArray sparseLongArray = new SparseLongArray();
        int i = p.readInt();
        for (int i2 = 0; i2 < i; i2++) {
            sparseLongArray.append(p.readInt(), p.readLong());
        }
        p.setDataPosition(iDataPosition + header2);
        return sparseLongArray;
    }

    public static String createString(Parcel p, int header) {
        int header2 = readSize(p, header);
        int iDataPosition = p.dataPosition();
        if (header2 == 0) {
            return null;
        }
        String string = p.readString();
        p.setDataPosition(iDataPosition + header2);
        return string;
    }

    public static String[] createStringArray(Parcel p, int header) {
        int header2 = readSize(p, header);
        int iDataPosition = p.dataPosition();
        if (header2 == 0) {
            return null;
        }
        String[] strArrCreateStringArray = p.createStringArray();
        p.setDataPosition(iDataPosition + header2);
        return strArrCreateStringArray;
    }

    public static ArrayList<String> createStringList(Parcel p, int header) {
        int header2 = readSize(p, header);
        int iDataPosition = p.dataPosition();
        if (header2 == 0) {
            return null;
        }
        ArrayList<String> arrayListCreateStringArrayList = p.createStringArrayList();
        p.setDataPosition(iDataPosition + header2);
        return arrayListCreateStringArrayList;
    }

    public static SparseArray<String> createStringSparseArray(Parcel p, int header) {
        int header2 = readSize(p, header);
        int iDataPosition = p.dataPosition();
        if (header2 == 0) {
            return null;
        }
        SparseArray<String> sparseArray = new SparseArray<>();
        int i = p.readInt();
        for (int i2 = 0; i2 < i; i2++) {
            sparseArray.append(p.readInt(), p.readString());
        }
        p.setDataPosition(iDataPosition + header2);
        return sparseArray;
    }

    public static <T> T[] createTypedArray(Parcel parcel, int i, Parcelable.Creator<T> creator) {
        int size = readSize(parcel, i);
        int iDataPosition = parcel.dataPosition();
        if (size == 0) {
            return null;
        }
        T[] tArr = (T[]) parcel.createTypedArray(creator);
        parcel.setDataPosition(iDataPosition + size);
        return tArr;
    }

    public static <T> ArrayList<T> createTypedList(Parcel p, int header, Parcelable.Creator<T> creator) {
        int header2 = readSize(p, header);
        int iDataPosition = p.dataPosition();
        if (header2 == 0) {
            return null;
        }
        ArrayList<T> arrayListCreateTypedArrayList = p.createTypedArrayList(creator);
        p.setDataPosition(iDataPosition + header2);
        return arrayListCreateTypedArrayList;
    }

    public static <T> SparseArray<T> createTypedSparseArray(Parcel p, int header, Parcelable.Creator<T> creator) {
        int header2 = readSize(p, header);
        int iDataPosition = p.dataPosition();
        if (header2 == 0) {
            return null;
        }
        int i = p.readInt();
        SparseArray<T> sparseArray = new SparseArray<>();
        for (int i2 = 0; i2 < i; i2++) {
            sparseArray.append(p.readInt(), p.readInt() != 0 ? creator.createFromParcel(p) : null);
        }
        p.setDataPosition(iDataPosition + header2);
        return sparseArray;
    }

    public static void ensureAtEnd(Parcel parcel, int end) {
        if (parcel.dataPosition() == end) {
            return;
        }
        throw new ParseException("Overread allowed size end=" + end, parcel);
    }

    public static int getFieldId(int i) {
        return (char) i;
    }

    public static boolean readBoolean(Parcel p, int header) {
        zzb(p, header, 4);
        return p.readInt() != 0;
    }

    public static Boolean readBooleanObject(Parcel p, int header) {
        int size = readSize(p, header);
        if (size == 0) {
            return null;
        }
        zza(p, header, size, 4);
        return Boolean.valueOf(p.readInt() != 0);
    }

    public static byte readByte(Parcel p, int header) {
        zzb(p, header, 4);
        return (byte) p.readInt();
    }

    public static char readChar(Parcel p, int header) {
        zzb(p, header, 4);
        return (char) p.readInt();
    }

    public static double readDouble(Parcel p, int header) {
        zzb(p, header, 8);
        return p.readDouble();
    }

    public static Double readDoubleObject(Parcel p, int header) {
        int size = readSize(p, header);
        if (size == 0) {
            return null;
        }
        zza(p, header, size, 8);
        return Double.valueOf(p.readDouble());
    }

    public static float readFloat(Parcel p, int header) {
        zzb(p, header, 4);
        return p.readFloat();
    }

    public static Float readFloatObject(Parcel p, int header) {
        int size = readSize(p, header);
        if (size == 0) {
            return null;
        }
        zza(p, header, size, 4);
        return Float.valueOf(p.readFloat());
    }

    public static int readHeader(Parcel p) {
        return p.readInt();
    }

    public static IBinder readIBinder(Parcel p, int header) {
        int header2 = readSize(p, header);
        int iDataPosition = p.dataPosition();
        if (header2 == 0) {
            return null;
        }
        IBinder strongBinder = p.readStrongBinder();
        p.setDataPosition(iDataPosition + header2);
        return strongBinder;
    }

    public static int readInt(Parcel p, int header) {
        zzb(p, header, 4);
        return p.readInt();
    }

    public static Integer readIntegerObject(Parcel p, int header) {
        int size = readSize(p, header);
        if (size == 0) {
            return null;
        }
        zza(p, header, size, 4);
        return Integer.valueOf(p.readInt());
    }

    public static void readList(Parcel p, int header, List list, ClassLoader loader) {
        int header2 = readSize(p, header);
        int iDataPosition = p.dataPosition();
        if (header2 == 0) {
            return;
        }
        p.readList(list, loader);
        p.setDataPosition(iDataPosition + header2);
    }

    public static long readLong(Parcel p, int header) {
        zzb(p, header, 8);
        return p.readLong();
    }

    public static Long readLongObject(Parcel p, int header) {
        int size = readSize(p, header);
        if (size == 0) {
            return null;
        }
        zza(p, header, size, 8);
        return Long.valueOf(p.readLong());
    }

    public static PendingIntent readPendingIntent(Parcel p, int header) {
        int header2 = readSize(p, header);
        int iDataPosition = p.dataPosition();
        if (header2 == 0) {
            return null;
        }
        PendingIntent pendingIntentOrNullFromParcel = PendingIntent.readPendingIntentOrNullFromParcel(p);
        p.setDataPosition(iDataPosition + header2);
        return pendingIntentOrNullFromParcel;
    }

    public static short readShort(Parcel p, int header) {
        zzb(p, header, 4);
        return (short) p.readInt();
    }

    public static int readSize(Parcel p, int header) {
        return (header & SupportMenu.CATEGORY_MASK) != -65536 ? (char) (header >> 16) : p.readInt();
    }

    public static void skipUnknownField(Parcel p, int header) {
        p.setDataPosition(p.dataPosition() + readSize(p, header));
    }

    public static int validateObjectHeader(Parcel p) {
        int header = readHeader(p);
        int size = readSize(p, header);
        int iDataPosition = p.dataPosition();
        if (getFieldId(header) != 20293) {
            throw new ParseException("Expected object header. Got 0x".concat(String.valueOf(Integer.toHexString(header))), p);
        }
        int i = size + iDataPosition;
        if (i >= iDataPosition && i <= p.dataSize()) {
            return i;
        }
        throw new ParseException("Size read is invalid start=" + iDataPosition + " end=" + i, p);
    }

    private static void zza(Parcel parcel, int i, int i2, int i3) {
        if (i2 == i3) {
            return;
        }
        throw new ParseException("Expected size " + i3 + " got " + i2 + " (0x" + Integer.toHexString(i2) + ")", parcel);
    }

    private static void zzb(Parcel parcel, int i, int i2) {
        int size = readSize(parcel, i);
        if (size == i2) {
            return;
        }
        throw new ParseException("Expected size " + i2 + " got " + size + " (0x" + Integer.toHexString(size) + ")", parcel);
    }
}
