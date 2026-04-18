package io.perfmark;

import javax.annotation.Nullable;

/* JADX INFO: loaded from: classes8.dex */
public final class Tag {
    final long tagId;

    @Nullable
    final String tagName;

    Tag(@Nullable String tagName, long tagId) {
        this.tagName = tagName;
        this.tagId = tagId;
    }
}
