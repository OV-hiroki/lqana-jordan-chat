package com.google.firebase.firestore.model;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/* JADX INFO: loaded from: classes.dex */
public final class ResourcePath extends BasePath<ResourcePath> {
    public static final ResourcePath EMPTY = new ResourcePath(Collections.emptyList());

    @Override // com.google.firebase.firestore.model.BasePath
    /* bridge */ /* synthetic */ BasePath createPathWithSegments(List list) {
        return createPathWithSegments((List<String>) list);
    }

    private ResourcePath(List<String> segments) {
        super(segments);
    }

    @Override // com.google.firebase.firestore.model.BasePath
    ResourcePath createPathWithSegments(List<String> segments) {
        return new ResourcePath(segments);
    }

    public static ResourcePath fromSegments(List<String> segments) {
        return segments.isEmpty() ? EMPTY : new ResourcePath(segments);
    }

    public static ResourcePath fromString(String path) {
        if (path.contains("//")) {
            throw new IllegalArgumentException("Invalid path (" + path + "). Paths must not contain // in them.");
        }
        String[] rawSegments = path.split("/");
        ArrayList<String> segments = new ArrayList<>(rawSegments.length);
        for (String segment : rawSegments) {
            if (!segment.isEmpty()) {
                segments.add(segment);
            }
        }
        return new ResourcePath(segments);
    }

    @Override // com.google.firebase.firestore.model.BasePath
    public String canonicalString() {
        StringBuilder builder = new StringBuilder();
        for (int i = 0; i < this.segments.size(); i++) {
            if (i > 0) {
                builder.append("/");
            }
            builder.append(this.segments.get(i));
        }
        return builder.toString();
    }
}
