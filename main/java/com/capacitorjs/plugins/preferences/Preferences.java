package com.capacitorjs.plugins.preferences;

import android.content.Context;
import android.content.SharedPreferences;
import java.util.Set;

/* JADX INFO: loaded from: classes5.dex */
public class Preferences {
    private SharedPreferences preferences;

    /* JADX INFO: Access modifiers changed from: private */
    interface PreferencesOperation {
        void execute(SharedPreferences.Editor editor);
    }

    Preferences(Context context, PreferencesConfiguration configuration) {
        this.preferences = context.getSharedPreferences(configuration.group, 0);
    }

    public String get(String key) {
        return this.preferences.getString(key, null);
    }

    public void set(final String key, final String value) {
        executeOperation(new PreferencesOperation() { // from class: com.capacitorjs.plugins.preferences.Preferences$$ExternalSyntheticLambda0
            @Override // com.capacitorjs.plugins.preferences.Preferences.PreferencesOperation
            public final void execute(SharedPreferences.Editor editor) {
                editor.putString(key, value);
            }
        });
    }

    public void remove(final String key) {
        executeOperation(new PreferencesOperation() { // from class: com.capacitorjs.plugins.preferences.Preferences$$ExternalSyntheticLambda2
            @Override // com.capacitorjs.plugins.preferences.Preferences.PreferencesOperation
            public final void execute(SharedPreferences.Editor editor) {
                editor.remove(key);
            }
        });
    }

    public Set<String> keys() {
        return this.preferences.getAll().keySet();
    }

    public void clear() {
        executeOperation(new PreferencesOperation() { // from class: com.capacitorjs.plugins.preferences.Preferences$$ExternalSyntheticLambda1
            @Override // com.capacitorjs.plugins.preferences.Preferences.PreferencesOperation
            public final void execute(SharedPreferences.Editor editor) {
                editor.clear();
            }
        });
    }

    private void executeOperation(PreferencesOperation op) {
        SharedPreferences.Editor editor = this.preferences.edit();
        op.execute(editor);
        editor.apply();
    }
}
