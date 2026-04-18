package io.grpc.internal;

import java.io.InputStream;
import javax.annotation.Nullable;

/* JADX INFO: loaded from: classes8.dex */
public interface StreamListener {

    public interface MessageProducer {
        @Nullable
        InputStream next();
    }

    void messagesAvailable(MessageProducer messageProducer);

    void onReady();
}
