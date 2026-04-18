package com.capacitorjs.plugins.preferences;

/* JADX INFO: loaded from: classes5.dex */
public class PreferencesConfiguration implements Cloneable {
    static final PreferencesConfiguration DEFAULTS = new PreferencesConfiguration();
    String group;

    static {
        DEFAULTS.group = "CapacitorStorage";
    }

    /* JADX INFO: renamed from: clone, reason: merged with bridge method [inline-methods] */
    public PreferencesConfiguration m103clone() throws CloneNotSupportedException {
        return (PreferencesConfiguration) super.clone();
    }
}
