package com.google.firebase.firestore.auth;

/* JADX INFO: loaded from: classes.dex */
public final class User {
    public static final User UNAUTHENTICATED = new User(null);
    private final String uid;

    public User(String uid) {
        this.uid = uid;
    }

    public String getUid() {
        return this.uid;
    }

    public boolean isAuthenticated() {
        return this.uid != null;
    }

    public boolean equals(Object o) {
        if (this == o) {
            return true;
        }
        if (o == null || getClass() != o.getClass()) {
            return false;
        }
        User user = (User) o;
        if (this.uid != null) {
            return this.uid.equals(user.uid);
        }
        if (user.uid == null) {
            return true;
        }
        return false;
    }

    public int hashCode() {
        if (this.uid != null) {
            return this.uid.hashCode();
        }
        return 0;
    }

    public String toString() {
        return "User(uid:" + this.uid + ")";
    }
}
