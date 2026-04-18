package com.google.firebase.heartbeatinfo;

import java.util.List;

/* JADX INFO: loaded from: classes.dex */
public abstract class HeartBeatResult {
    public abstract List<String> getUsedDates();

    public abstract String getUserAgent();

    public static HeartBeatResult create(String userAgent, List<String> dateList) {
        return new AutoValue_HeartBeatResult(userAgent, dateList);
    }
}
