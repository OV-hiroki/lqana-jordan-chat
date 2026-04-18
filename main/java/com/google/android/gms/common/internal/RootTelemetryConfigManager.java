package com.google.android.gms.common.internal;

/* JADX INFO: compiled from: com.google.android.gms:play-services-basement@@18.1.0 */
/* JADX INFO: loaded from: classes.dex */
public final class RootTelemetryConfigManager {
    private static RootTelemetryConfigManager zza = null;
    private static final RootTelemetryConfiguration zzb = new RootTelemetryConfiguration(0, false, false, 0, 0);
    private RootTelemetryConfiguration zzc;

    private RootTelemetryConfigManager() {
    }

    public static synchronized RootTelemetryConfigManager getInstance() {
        if (zza == null) {
            zza = new RootTelemetryConfigManager();
        }
        return zza;
    }

    public RootTelemetryConfiguration getConfig() {
        return this.zzc;
    }

    public final synchronized void zza(RootTelemetryConfiguration rootTelemetryConfiguration) {
        if (rootTelemetryConfiguration == null) {
            rootTelemetryConfiguration = zzb;
        } else {
            RootTelemetryConfiguration rootTelemetryConfiguration2 = this.zzc;
            if (rootTelemetryConfiguration2 == null || rootTelemetryConfiguration2.getVersion() < rootTelemetryConfiguration.getVersion()) {
            }
        }
        this.zzc = rootTelemetryConfiguration;
    }
}
