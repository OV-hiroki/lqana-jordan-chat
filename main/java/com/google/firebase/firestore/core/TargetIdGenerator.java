package com.google.firebase.firestore.core;

import com.google.firebase.firestore.util.Assert;

/* JADX INFO: loaded from: classes.dex */
public class TargetIdGenerator {
    private static final int QUERY_CACHE_ID = 0;
    private static final int RESERVED_BITS = 1;
    private static final int SYNC_ENGINE_ID = 1;
    private int generatorId;
    private int nextId;

    public static TargetIdGenerator forTargetCache(int after) {
        TargetIdGenerator generator = new TargetIdGenerator(0, after);
        generator.nextId();
        return generator;
    }

    public static TargetIdGenerator forSyncEngine() {
        return new TargetIdGenerator(1, 1);
    }

    TargetIdGenerator(int generatorId, int seed) {
        Assert.hardAssert((generatorId & 1) == generatorId, "Generator ID %d contains more than %d reserved bits", Integer.valueOf(generatorId), 1);
        this.generatorId = generatorId;
        seek(seed);
    }

    private void seek(int targetId) {
        Assert.hardAssert((targetId & 1) == this.generatorId, "Cannot supply target ID from different generator ID", new Object[0]);
        this.nextId = targetId;
    }

    public int nextId() {
        int nextId = this.nextId;
        this.nextId += 2;
        return nextId;
    }
}
