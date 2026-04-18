package com.google.firebase;

import android.os.Parcel;
import android.os.Parcelable;
import com.google.firebase.firestore.util.Preconditions;
import java.util.Date;
import kotlin.time.DurationKt;

/* JADX INFO: loaded from: classes.dex */
public final class Timestamp implements Comparable<Timestamp>, Parcelable {
    public static final Parcelable.Creator<Timestamp> CREATOR = new Parcelable.Creator<Timestamp>() { // from class: com.google.firebase.Timestamp.1
        /* JADX WARN: Can't rename method to resolve collision */
        @Override // android.os.Parcelable.Creator
        public Timestamp createFromParcel(Parcel source) {
            return new Timestamp(source);
        }

        /* JADX WARN: Can't rename method to resolve collision */
        @Override // android.os.Parcelable.Creator
        public Timestamp[] newArray(int size) {
            return new Timestamp[size];
        }
    };
    private final int nanoseconds;
    private final long seconds;

    public Timestamp(long seconds, int nanoseconds) {
        validateRange(seconds, nanoseconds);
        this.seconds = seconds;
        this.nanoseconds = nanoseconds;
    }

    protected Timestamp(Parcel in) {
        this.seconds = in.readLong();
        this.nanoseconds = in.readInt();
    }

    public Timestamp(Date date) {
        long millis = date.getTime();
        long seconds = millis / 1000;
        int nanoseconds = ((int) (millis % 1000)) * DurationKt.NANOS_IN_MILLIS;
        if (nanoseconds < 0) {
            seconds--;
            nanoseconds += 1000000000;
        }
        validateRange(seconds, nanoseconds);
        this.seconds = seconds;
        this.nanoseconds = nanoseconds;
    }

    public static Timestamp now() {
        return new Timestamp(new Date());
    }

    public long getSeconds() {
        return this.seconds;
    }

    public int getNanoseconds() {
        return this.nanoseconds;
    }

    public Date toDate() {
        return new Date((this.seconds * 1000) + ((long) (this.nanoseconds / DurationKt.NANOS_IN_MILLIS)));
    }

    @Override // android.os.Parcelable
    public int describeContents() {
        return 0;
    }

    @Override // android.os.Parcelable
    public void writeToParcel(Parcel dest, int flags) {
        dest.writeLong(this.seconds);
        dest.writeInt(this.nanoseconds);
    }

    @Override // java.lang.Comparable
    public int compareTo(Timestamp other) {
        if (this.seconds == other.seconds) {
            return Integer.signum(this.nanoseconds - other.nanoseconds);
        }
        return Long.signum(this.seconds - other.seconds);
    }

    public boolean equals(Object other) {
        if (other == this) {
            return true;
        }
        return (other instanceof Timestamp) && compareTo((Timestamp) other) == 0;
    }

    public int hashCode() {
        int result = ((int) this.seconds) * 37;
        return (37 * ((37 * result) + ((int) (this.seconds >> 32)))) + this.nanoseconds;
    }

    public String toString() {
        return "Timestamp(seconds=" + this.seconds + ", nanoseconds=" + this.nanoseconds + ")";
    }

    private static void validateRange(long seconds, int nanoseconds) {
        Preconditions.checkArgument(nanoseconds >= 0, "Timestamp nanoseconds out of range: %s", Integer.valueOf(nanoseconds));
        Preconditions.checkArgument(((double) nanoseconds) < 1.0E9d, "Timestamp nanoseconds out of range: %s", Integer.valueOf(nanoseconds));
        Preconditions.checkArgument(seconds >= -62135596800L, "Timestamp seconds out of range: %s", Long.valueOf(seconds));
        Preconditions.checkArgument(seconds < 253402300800L, "Timestamp seconds out of range: %s", Long.valueOf(seconds));
    }
}
