package com.google.firebase.firestore.model;

import com.google.firebase.firestore.model.BasePath;
import com.google.firebase.firestore.util.Assert;
import com.google.firebase.firestore.util.Util;
import java.util.ArrayList;
import java.util.List;

/* JADX INFO: loaded from: classes.dex */
public abstract class BasePath<B extends BasePath<B>> implements Comparable<B> {
    final List<String> segments;

    public abstract String canonicalString();

    abstract B createPathWithSegments(List<String> list);

    BasePath(List<String> segments) {
        this.segments = segments;
    }

    public String getSegment(int index) {
        return this.segments.get(index);
    }

    public B append(String str) {
        ArrayList arrayList = new ArrayList(this.segments);
        arrayList.add(str);
        return (B) createPathWithSegments(arrayList);
    }

    public B append(B b) {
        ArrayList arrayList = new ArrayList(this.segments);
        arrayList.addAll(b.segments);
        return (B) createPathWithSegments(arrayList);
    }

    public B popFirst() {
        return (B) popFirst(1);
    }

    public B popFirst(int i) {
        int length = length();
        Assert.hardAssert(length >= i, "Can't call popFirst with count > length() (%d > %d)", Integer.valueOf(i), Integer.valueOf(length));
        return (B) createPathWithSegments(this.segments.subList(i, length));
    }

    public B popLast() {
        return (B) createPathWithSegments(this.segments.subList(0, length() - 1));
    }

    public B keepFirst(int i) {
        return (B) createPathWithSegments(this.segments.subList(0, i));
    }

    @Override // java.lang.Comparable
    public int compareTo(B o) {
        int myLength = length();
        int theirLength = o.length();
        for (int i = 0; i < myLength && i < theirLength; i++) {
            int localCompare = getSegment(i).compareTo(o.getSegment(i));
            if (localCompare != 0) {
                return localCompare;
            }
        }
        return Util.compareIntegers(myLength, theirLength);
    }

    public String getLastSegment() {
        return this.segments.get(length() - 1);
    }

    public String getFirstSegment() {
        return this.segments.get(0);
    }

    public boolean isEmpty() {
        return length() == 0;
    }

    public boolean isPrefixOf(B path) {
        if (length() > path.length()) {
            return false;
        }
        for (int i = 0; i < length(); i++) {
            if (!getSegment(i).equals(path.getSegment(i))) {
                return false;
            }
        }
        return true;
    }

    public boolean isImmediateParentOf(B potentialChild) {
        if (length() + 1 != potentialChild.length()) {
            return false;
        }
        for (int i = 0; i < length(); i++) {
            if (!getSegment(i).equals(potentialChild.getSegment(i))) {
                return false;
            }
        }
        return true;
    }

    public String toString() {
        return canonicalString();
    }

    public int length() {
        return this.segments.size();
    }

    public final boolean equals(Object o) {
        if (this == o) {
            return true;
        }
        return (o instanceof BasePath) && compareTo((BasePath) o) == 0;
    }

    public int hashCode() {
        int result = (37 * 1) + getClass().hashCode();
        return (37 * result) + this.segments.hashCode();
    }
}
