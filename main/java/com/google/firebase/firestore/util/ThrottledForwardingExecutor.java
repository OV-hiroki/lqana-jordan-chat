package com.google.firebase.firestore.util;

import java.util.concurrent.Executor;
import java.util.concurrent.RejectedExecutionException;
import java.util.concurrent.Semaphore;

/* JADX INFO: loaded from: classes.dex */
class ThrottledForwardingExecutor implements Executor {
    private final Semaphore availableSlots;
    private final Executor executor;

    ThrottledForwardingExecutor(int maximumConcurrency, Executor executor) {
        this.availableSlots = new Semaphore(maximumConcurrency);
        this.executor = executor;
    }

    @Override // java.util.concurrent.Executor
    public void execute(final Runnable command) {
        if (this.availableSlots.tryAcquire()) {
            try {
                this.executor.execute(new Runnable() { // from class: com.google.firebase.firestore.util.ThrottledForwardingExecutor$$ExternalSyntheticLambda0
                    @Override // java.lang.Runnable
                    public final void run() {
                        this.f$0.m302xc0e914ff(command);
                    }
                });
                return;
            } catch (RejectedExecutionException e) {
                command.run();
                return;
            }
        }
        command.run();
    }

    /* JADX INFO: renamed from: lambda$execute$0$com-google-firebase-firestore-util-ThrottledForwardingExecutor, reason: not valid java name */
    /* synthetic */ void m302xc0e914ff(Runnable command) {
        command.run();
        this.availableSlots.release();
    }
}
