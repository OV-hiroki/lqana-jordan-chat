package com.google.firebase.concurrent;

import com.google.firebase.components.Preconditions;
import java.util.concurrent.Executor;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.Semaphore;

/* JADX INFO: loaded from: classes.dex */
class LimitedConcurrencyExecutor implements Executor {
    private final Executor delegate;
    private final LinkedBlockingQueue<Runnable> queue = new LinkedBlockingQueue<>();
    private final Semaphore semaphore;

    LimitedConcurrencyExecutor(Executor delegate, int concurrency) {
        Preconditions.checkArgument(concurrency > 0, "concurrency must be positive.");
        this.delegate = delegate;
        this.semaphore = new Semaphore(concurrency, true);
    }

    @Override // java.util.concurrent.Executor
    public void execute(Runnable command) {
        this.queue.offer(command);
        maybeEnqueueNext();
    }

    private void maybeEnqueueNext() {
        while (this.semaphore.tryAcquire()) {
            Runnable next = this.queue.poll();
            if (next != null) {
                this.delegate.execute(decorate(next));
            } else {
                this.semaphore.release();
                return;
            }
        }
    }

    private Runnable decorate(final Runnable command) {
        return new Runnable() { // from class: com.google.firebase.concurrent.LimitedConcurrencyExecutor$$ExternalSyntheticLambda0
            @Override // java.lang.Runnable
            public final void run() {
                this.f$0.m160x96c64136(command);
            }
        };
    }

    /* JADX INFO: renamed from: lambda$decorate$0$com-google-firebase-concurrent-LimitedConcurrencyExecutor, reason: not valid java name */
    /* synthetic */ void m160x96c64136(Runnable command) {
        try {
            command.run();
        } finally {
            this.semaphore.release();
            maybeEnqueueNext();
        }
    }
}
