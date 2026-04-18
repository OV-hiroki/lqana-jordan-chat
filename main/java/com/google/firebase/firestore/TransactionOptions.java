package com.google.firebase.firestore;

/* JADX INFO: loaded from: classes.dex */
public final class TransactionOptions {
    static final TransactionOptions DEFAULT = new Builder().build();
    static final int DEFAULT_MAX_ATTEMPTS_COUNT = 5;
    private final int maxAttempts;

    private TransactionOptions(int maxAttempts) {
        this.maxAttempts = maxAttempts;
    }

    public static final class Builder {
        private int maxAttempts;

        public Builder() {
            this.maxAttempts = 5;
        }

        public Builder(TransactionOptions options) {
            this.maxAttempts = 5;
            this.maxAttempts = options.maxAttempts;
        }

        public Builder setMaxAttempts(int maxAttempts) {
            if (maxAttempts < 1) {
                throw new IllegalArgumentException("Max attempts must be at least 1");
            }
            this.maxAttempts = maxAttempts;
            return this;
        }

        public TransactionOptions build() {
            return new TransactionOptions(this.maxAttempts);
        }
    }

    public int getMaxAttempts() {
        return this.maxAttempts;
    }

    public boolean equals(Object o) {
        if (this == o) {
            return true;
        }
        if (o == null || getClass() != o.getClass()) {
            return false;
        }
        TransactionOptions that = (TransactionOptions) o;
        if (this.maxAttempts == that.maxAttempts) {
            return true;
        }
        return false;
    }

    public int hashCode() {
        return this.maxAttempts;
    }

    public String toString() {
        return "TransactionOptions{maxAttempts=" + this.maxAttempts + '}';
    }
}
