package com.google.firebase.heartbeatinfo;

import android.content.Context;
import android.content.SharedPreferences;
import android.os.Build;
import java.text.SimpleDateFormat;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

/* JADX INFO: loaded from: classes.dex */
class HeartBeatInfoStorage {
    private static final String GLOBAL = "fire-global";
    private static final String HEARTBEAT_PREFERENCES_NAME = "FirebaseHeartBeat";
    private static final int HEART_BEAT_COUNT_LIMIT = 30;
    private static final String HEART_BEAT_COUNT_TAG = "fire-count";
    private static final String LAST_STORED_DATE = "last-used-date";
    private static final String PREFERENCES_NAME = "FirebaseAppHeartBeat";
    private static HeartBeatInfoStorage instance = null;
    private final SharedPreferences firebaseSharedPreferences;

    public HeartBeatInfoStorage(Context applicationContext, String persistenceKey) {
        this.firebaseSharedPreferences = applicationContext.getSharedPreferences(HEARTBEAT_PREFERENCES_NAME + persistenceKey, 0);
    }

    HeartBeatInfoStorage(SharedPreferences firebaseSharedPreferences) {
        this.firebaseSharedPreferences = firebaseSharedPreferences;
    }

    int getHeartBeatCount() {
        return (int) this.firebaseSharedPreferences.getLong(HEART_BEAT_COUNT_TAG, 0L);
    }

    synchronized void deleteAllHeartBeats() {
        SharedPreferences.Editor editor = this.firebaseSharedPreferences.edit();
        int counter = 0;
        for (Map.Entry<String, ?> entry : this.firebaseSharedPreferences.getAll().entrySet()) {
            if (entry.getValue() instanceof Set) {
                Set<String> dates = (Set) entry.getValue();
                String today = getFormattedDate(System.currentTimeMillis());
                String key = entry.getKey();
                if (dates.contains(today)) {
                    Set<String> userAgentDateSet = new HashSet<>();
                    userAgentDateSet.add(today);
                    counter++;
                    editor.putStringSet(key, userAgentDateSet);
                } else {
                    editor.remove(key);
                }
            }
        }
        if (counter == 0) {
            editor.remove(HEART_BEAT_COUNT_TAG);
        } else {
            editor.putLong(HEART_BEAT_COUNT_TAG, counter);
        }
        editor.commit();
    }

    synchronized List<HeartBeatResult> getAllHeartBeats() {
        ArrayList<HeartBeatResult> heartBeatResults;
        heartBeatResults = new ArrayList<>();
        for (Map.Entry<String, ?> entry : this.firebaseSharedPreferences.getAll().entrySet()) {
            if (entry.getValue() instanceof Set) {
                Set<String> dates = new HashSet<>((Set) entry.getValue());
                String today = getFormattedDate(System.currentTimeMillis());
                dates.remove(today);
                if (!dates.isEmpty()) {
                    heartBeatResults.add(HeartBeatResult.create(entry.getKey(), new ArrayList(dates)));
                }
            }
        }
        updateGlobalHeartBeat(System.currentTimeMillis());
        return heartBeatResults;
    }

    private synchronized String getStoredUserAgentString(String dateString) {
        for (Map.Entry<String, ?> entry : this.firebaseSharedPreferences.getAll().entrySet()) {
            if (entry.getValue() instanceof Set) {
                Set<String> dateSet = (Set) entry.getValue();
                for (String date : dateSet) {
                    if (dateString.equals(date)) {
                        return entry.getKey();
                    }
                }
            }
        }
        return null;
    }

    private synchronized void updateStoredUserAgent(String userAgent, String dateString) {
        removeStoredDate(dateString);
        Set<String> userAgentDateSet = new HashSet<>(this.firebaseSharedPreferences.getStringSet(userAgent, new HashSet()));
        userAgentDateSet.add(dateString);
        this.firebaseSharedPreferences.edit().putStringSet(userAgent, userAgentDateSet).commit();
    }

    private synchronized void removeStoredDate(String dateString) {
        String userAgentString = getStoredUserAgentString(dateString);
        if (userAgentString == null) {
            return;
        }
        Set<String> userAgentDateSet = new HashSet<>(this.firebaseSharedPreferences.getStringSet(userAgentString, new HashSet()));
        userAgentDateSet.remove(dateString);
        if (userAgentDateSet.isEmpty()) {
            this.firebaseSharedPreferences.edit().remove(userAgentString).commit();
        } else {
            this.firebaseSharedPreferences.edit().putStringSet(userAgentString, userAgentDateSet).commit();
        }
    }

    synchronized void postHeartBeatCleanUp() {
        String dateString = getFormattedDate(System.currentTimeMillis());
        this.firebaseSharedPreferences.edit().putString(LAST_STORED_DATE, dateString).commit();
        removeStoredDate(dateString);
    }

    private synchronized String getFormattedDate(long millis) {
        if (Build.VERSION.SDK_INT >= 26) {
            Instant instant = new Date(millis).toInstant();
            LocalDateTime ldt = instant.atOffset(ZoneOffset.UTC).toLocalDateTime();
            return ldt.format(DateTimeFormatter.ISO_LOCAL_DATE);
        }
        return new SimpleDateFormat("yyyy-MM-dd", Locale.UK).format(new Date(millis));
    }

    synchronized void storeHeartBeat(long millis, String userAgentString) {
        String dateString = getFormattedDate(millis);
        String lastDateString = this.firebaseSharedPreferences.getString(LAST_STORED_DATE, "");
        if (lastDateString.equals(dateString)) {
            String storedUserAgentString = getStoredUserAgentString(dateString);
            if (storedUserAgentString == null) {
                return;
            }
            if (storedUserAgentString.equals(userAgentString)) {
                return;
            }
            updateStoredUserAgent(userAgentString, dateString);
            return;
        }
        long heartBeatCount = this.firebaseSharedPreferences.getLong(HEART_BEAT_COUNT_TAG, 0L);
        if (heartBeatCount + 1 == 30) {
            cleanUpStoredHeartBeats();
            heartBeatCount = this.firebaseSharedPreferences.getLong(HEART_BEAT_COUNT_TAG, 0L);
        }
        Set<String> userAgentDateSet = new HashSet<>(this.firebaseSharedPreferences.getStringSet(userAgentString, new HashSet()));
        userAgentDateSet.add(dateString);
        this.firebaseSharedPreferences.edit().putStringSet(userAgentString, userAgentDateSet).putLong(HEART_BEAT_COUNT_TAG, heartBeatCount + 1).putString(LAST_STORED_DATE, dateString).commit();
    }

    private synchronized void cleanUpStoredHeartBeats() {
        long heartBeatCount = this.firebaseSharedPreferences.getLong(HEART_BEAT_COUNT_TAG, 0L);
        String lowestDate = null;
        String userAgentString = "";
        for (Map.Entry<String, ?> entry : this.firebaseSharedPreferences.getAll().entrySet()) {
            if (entry.getValue() instanceof Set) {
                Set<String> dateSet = (Set) entry.getValue();
                for (String date : dateSet) {
                    if (lowestDate == null || lowestDate.compareTo(date) > 0) {
                        lowestDate = date;
                        userAgentString = entry.getKey();
                    }
                }
            }
        }
        Set<String> userAgentDateSet = new HashSet<>(this.firebaseSharedPreferences.getStringSet(userAgentString, new HashSet()));
        userAgentDateSet.remove(lowestDate);
        this.firebaseSharedPreferences.edit().putStringSet(userAgentString, userAgentDateSet).putLong(HEART_BEAT_COUNT_TAG, heartBeatCount - 1).commit();
    }

    synchronized long getLastGlobalHeartBeat() {
        return this.firebaseSharedPreferences.getLong(GLOBAL, -1L);
    }

    synchronized void updateGlobalHeartBeat(long millis) {
        this.firebaseSharedPreferences.edit().putLong(GLOBAL, millis).commit();
    }

    synchronized boolean isSameDateUtc(long base, long target) {
        return getFormattedDate(base).equals(getFormattedDate(target));
    }

    synchronized boolean shouldSendSdkHeartBeat(String heartBeatTag, long millis) {
        if (this.firebaseSharedPreferences.contains(heartBeatTag)) {
            if (isSameDateUtc(this.firebaseSharedPreferences.getLong(heartBeatTag, -1L), millis)) {
                return false;
            }
            this.firebaseSharedPreferences.edit().putLong(heartBeatTag, millis).commit();
            return true;
        }
        this.firebaseSharedPreferences.edit().putLong(heartBeatTag, millis).commit();
        return true;
    }

    synchronized boolean shouldSendGlobalHeartBeat(long millis) {
        return shouldSendSdkHeartBeat(GLOBAL, millis);
    }
}
