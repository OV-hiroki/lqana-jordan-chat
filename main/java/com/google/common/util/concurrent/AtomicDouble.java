package com.google.common.util.concurrent;

import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.io.Serializable;
import java.util.concurrent.atomic.AtomicLong;

/* JADX INFO: loaded from: classes.dex */
@ElementTypesAreNonnullByDefault
public class AtomicDouble extends Number implements Serializable {
    private static final long serialVersionUID = 0;
    private transient AtomicLong value;

    public AtomicDouble(double initialValue) {
        this.value = new AtomicLong(Double.doubleToRawLongBits(initialValue));
    }

    public AtomicDouble() {
        this(0.0d);
    }

    public final double get() {
        return Double.longBitsToDouble(this.value.get());
    }

    public final void set(double newValue) {
        long next = Double.doubleToRawLongBits(newValue);
        this.value.set(next);
    }

    public final void lazySet(double newValue) {
        long next = Double.doubleToRawLongBits(newValue);
        this.value.lazySet(next);
    }

    public final double getAndSet(double newValue) {
        long next = Double.doubleToRawLongBits(newValue);
        return Double.longBitsToDouble(this.value.getAndSet(next));
    }

    public final boolean compareAndSet(double expect, double update) {
        return this.value.compareAndSet(Double.doubleToRawLongBits(expect), Double.doubleToRawLongBits(update));
    }

    public final boolean weakCompareAndSet(double expect, double update) {
        return this.value.weakCompareAndSet(Double.doubleToRawLongBits(expect), Double.doubleToRawLongBits(update));
    }

    public final double getAndAdd(double delta) {
        long current;
        double currentVal;
        long next;
        do {
            current = this.value.get();
            currentVal = Double.longBitsToDouble(current);
            double nextVal = currentVal + delta;
            next = Double.doubleToRawLongBits(nextVal);
        } while (!this.value.compareAndSet(current, next));
        return currentVal;
    }

    public final double addAndGet(double delta) {
        long current;
        double nextVal;
        long next;
        do {
            current = this.value.get();
            double currentVal = Double.longBitsToDouble(current);
            nextVal = currentVal + delta;
            next = Double.doubleToRawLongBits(nextVal);
        } while (!this.value.compareAndSet(current, next));
        return nextVal;
    }

    public String toString() {
        return Double.toString(get());
    }

    @Override // java.lang.Number
    public int intValue() {
        return (int) get();
    }

    @Override // java.lang.Number
    public long longValue() {
        return (long) get();
    }

    @Override // java.lang.Number
    public float floatValue() {
        return (float) get();
    }

    @Override // java.lang.Number
    public double doubleValue() {
        return get();
    }

    private void writeObject(ObjectOutputStream s) throws IOException {
        s.defaultWriteObject();
        s.writeDouble(get());
    }

    private void readObject(ObjectInputStream s) throws ClassNotFoundException, IOException {
        s.defaultReadObject();
        this.value = new AtomicLong();
        set(s.readDouble());
    }
}
