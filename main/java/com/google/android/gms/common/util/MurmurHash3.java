package com.google.android.gms.common.util;

import androidx.collection.ScatterMapKt;

/* JADX INFO: compiled from: com.google.android.gms:play-services-basement@@18.1.0 */
/* JADX INFO: loaded from: classes.dex */
public class MurmurHash3 {
    private MurmurHash3() {
    }

    /* JADX WARN: Can't fix incorrect switch cases order, some code will duplicate */
    public static int murmurhash3_x86_32(byte[] data, int offset, int len, int seed) {
        int i = (len & (-4)) + offset;
        while (offset < i) {
            int i2 = ((data[offset] & 255) | ((data[offset + 1] & 255) << 8) | ((data[offset + 2] & 255) << 16) | (data[offset + 3] << 24)) * ScatterMapKt.MurmurHashC1;
            int i3 = seed ^ (((i2 << 15) | (i2 >>> 17)) * 461845907);
            seed = (((i3 >>> 19) | (i3 << 13)) * 5) - 430675100;
            offset += 4;
        }
        int i4 = 0;
        switch (len & 3) {
            case 1:
                int i5 = ((data[i] & 255) | i4) * ScatterMapKt.MurmurHashC1;
                seed ^= ((i5 >>> 17) | (i5 << 15)) * 461845907;
                break;
            case 2:
                i4 |= (data[i + 1] & 255) << 8;
                int i52 = ((data[i] & 255) | i4) * ScatterMapKt.MurmurHashC1;
                seed ^= ((i52 >>> 17) | (i52 << 15)) * 461845907;
                break;
            case 3:
                i4 = (data[i + 2] & 255) << 16;
                i4 |= (data[i + 1] & 255) << 8;
                int i522 = ((data[i] & 255) | i4) * ScatterMapKt.MurmurHashC1;
                seed ^= ((i522 >>> 17) | (i522 << 15)) * 461845907;
                break;
        }
        int i6 = seed ^ len;
        int i7 = (i6 ^ (i6 >>> 16)) * (-2048144789);
        int i8 = (i7 ^ (i7 >>> 13)) * (-1028477387);
        return i8 ^ (i8 >>> 16);
    }
}
