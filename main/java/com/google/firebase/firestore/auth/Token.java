package com.google.firebase.firestore.auth;

/* JADX INFO: loaded from: classes.dex */
public final class Token {
    private final User user;
    private final String value;

    public Token(String value, User user) {
        this.value = value;
        this.user = user;
    }

    public String getValue() {
        return this.value;
    }

    public User getUser() {
        return this.user;
    }
}
