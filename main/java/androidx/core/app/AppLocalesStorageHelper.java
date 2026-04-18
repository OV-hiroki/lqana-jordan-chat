package androidx.core.app;

/* JADX INFO: loaded from: classes.dex */
public class AppLocalesStorageHelper {
    static final String APPLICATION_LOCALES_RECORD_FILE = "androidx.appcompat.app.AppCompatDelegate.application_locales_record_file";
    static final boolean DEBUG = false;
    static final String LOCALE_RECORD_ATTRIBUTE_TAG = "application_locales";
    static final String LOCALE_RECORD_FILE_TAG = "locales";
    static final String TAG = "AppLocalesStorageHelper";
    private static final Object sAppLocaleStorageSync = new Object();

    private AppLocalesStorageHelper() {
    }

    /* JADX WARN: Code restructure failed: missing block: B:20:0x0043, code lost:
    
        r1 = r3.getAttributeValue(null, androidx.core.app.AppLocalesStorageHelper.LOCALE_RECORD_ATTRIBUTE_TAG);
     */
    /* JADX WARN: Not initialized variable reg: 2, insn: 0x006c: IF  (r2 I:??[int, boolean, OBJECT, ARRAY, byte, short, char] A[D('fis' java.io.FileInputStream)]) == (0 ??[int, boolean, OBJECT, ARRAY, byte, short, char])  -> B:46:0x0074 (LINE:94), block:B:41:0x006c */
    /* JADX WARN: Removed duplicated region for block: B:37:0x0064  */
    /* JADX WARN: Removed duplicated region for block: B:38:0x0065 A[Catch: all -> 0x0078, TryCatch #2 {, blocks: (B:5:0x0005, B:23:0x0048, B:35:0x005e, B:39:0x006a, B:38:0x0065, B:42:0x006e, B:46:0x0074, B:48:0x0076, B:6:0x000c, B:7:0x0019, B:11:0x0024, B:17:0x0030, B:19:0x003c, B:32:0x0053), top: B:53:0x0005, inners: #0, #5 }] */
    /* JADX WARN: Removed duplicated region for block: B:57:0x0048 A[EXC_TOP_SPLITTER, PHI: r1
      0x0048: PHI (r1v2 'appLocales' java.lang.String) = (r1v0 'appLocales' java.lang.String), (r1v4 'appLocales' java.lang.String) binds: [B:33:0x005b, B:22:0x0046] A[DONT_GENERATE, DONT_INLINE], SYNTHETIC] */
    /*
        Code decompiled incorrectly, please refer to instructions dump.
        To view partially-correct code enable 'Show inconsistent code' option in preferences
    */
    public static java.lang.String readLocales(android.content.Context r9) {
        /*
            java.lang.Object r0 = androidx.core.app.AppLocalesStorageHelper.sAppLocaleStorageSync
            monitor-enter(r0)
            java.lang.String r1 = ""
            java.lang.String r2 = "androidx.appcompat.app.AppCompatDelegate.application_locales_record_file"
            java.io.FileInputStream r2 = r9.openFileInput(r2)     // Catch: java.io.FileNotFoundException -> L75 java.lang.Throwable -> L78
            org.xmlpull.v1.XmlPullParser r3 = android.util.Xml.newPullParser()     // Catch: java.lang.Throwable -> L4e java.io.IOException -> L50 org.xmlpull.v1.XmlPullParserException -> L52
            java.lang.String r4 = "UTF-8"
            r3.setInput(r2, r4)     // Catch: java.lang.Throwable -> L4e java.io.IOException -> L50 org.xmlpull.v1.XmlPullParserException -> L52
            int r4 = r3.getDepth()     // Catch: java.lang.Throwable -> L4e java.io.IOException -> L50 org.xmlpull.v1.XmlPullParserException -> L52
        L19:
            int r5 = r3.next()     // Catch: java.lang.Throwable -> L4e java.io.IOException -> L50 org.xmlpull.v1.XmlPullParserException -> L52
            r6 = r5
            r7 = 1
            if (r5 == r7) goto L46
            r5 = 3
            if (r6 != r5) goto L2a
            int r7 = r3.getDepth()     // Catch: java.lang.Throwable -> L4e java.io.IOException -> L50 org.xmlpull.v1.XmlPullParserException -> L52
            if (r7 <= r4) goto L46
        L2a:
            if (r6 == r5) goto L19
            r5 = 4
            if (r6 != r5) goto L30
            goto L19
        L30:
            java.lang.String r5 = r3.getName()     // Catch: java.lang.Throwable -> L4e java.io.IOException -> L50 org.xmlpull.v1.XmlPullParserException -> L52
            java.lang.String r7 = "locales"
            boolean r7 = r5.equals(r7)     // Catch: java.lang.Throwable -> L4e java.io.IOException -> L50 org.xmlpull.v1.XmlPullParserException -> L52
            if (r7 == 0) goto L45
            java.lang.String r7 = "application_locales"
            r8 = 0
            java.lang.String r7 = r3.getAttributeValue(r8, r7)     // Catch: java.lang.Throwable -> L4e java.io.IOException -> L50 org.xmlpull.v1.XmlPullParserException -> L52
            r1 = r7
            goto L46
        L45:
            goto L19
        L46:
            if (r2 == 0) goto L5e
        L48:
            r2.close()     // Catch: java.io.IOException -> L4c java.lang.Throwable -> L78
        L4b:
            goto L5e
        L4c:
            r3 = move-exception
            goto L4b
        L4e:
            r3 = move-exception
            goto L6c
        L50:
            r3 = move-exception
            goto L53
        L52:
            r3 = move-exception
        L53:
            java.lang.String r4 = "AppLocalesStorageHelper"
            java.lang.String r5 = "Reading app Locales : Unable to parse through file :androidx.appcompat.app.AppCompatDelegate.application_locales_record_file"
            android.util.Log.w(r4, r5)     // Catch: java.lang.Throwable -> L4e
            if (r2 == 0) goto L5e
            goto L48
        L5e:
            boolean r3 = r1.isEmpty()     // Catch: java.lang.Throwable -> L78
            if (r3 != 0) goto L65
            goto L6a
        L65:
            java.lang.String r3 = "androidx.appcompat.app.AppCompatDelegate.application_locales_record_file"
            r9.deleteFile(r3)     // Catch: java.lang.Throwable -> L78
        L6a:
            monitor-exit(r0)     // Catch: java.lang.Throwable -> L78
            return r1
        L6c:
            if (r2 == 0) goto L73
            r2.close()     // Catch: java.io.IOException -> L72 java.lang.Throwable -> L78
            goto L73
        L72:
            r4 = move-exception
        L73:
            throw r3     // Catch: java.lang.Throwable -> L78
        L75:
            r2 = move-exception
            monitor-exit(r0)     // Catch: java.lang.Throwable -> L78
            return r1
        L78:
            r1 = move-exception
            monitor-exit(r0)     // Catch: java.lang.Throwable -> L78
            throw r1
        */
        throw new UnsupportedOperationException("Method not decompiled: androidx.core.app.AppLocalesStorageHelper.readLocales(android.content.Context):java.lang.String");
    }

    /* JADX WARN: Removed duplicated region for block: B:44:0x004e A[EXC_TOP_SPLITTER, SYNTHETIC] */
    /*
        Code decompiled incorrectly, please refer to instructions dump.
        To view partially-correct code enable 'Show inconsistent code' option in preferences
    */
    public static void persistLocales(android.content.Context r6, java.lang.String r7) {
        /*
            java.lang.Object r0 = androidx.core.app.AppLocalesStorageHelper.sAppLocaleStorageSync
            monitor-enter(r0)
            java.lang.String r1 = ""
            boolean r1 = r7.equals(r1)     // Catch: java.lang.Throwable -> L73
            if (r1 == 0) goto L12
            java.lang.String r1 = "androidx.appcompat.app.AppCompatDelegate.application_locales_record_file"
            r6.deleteFile(r1)     // Catch: java.lang.Throwable -> L73
            monitor-exit(r0)     // Catch: java.lang.Throwable -> L73
            return
        L12:
            java.lang.String r1 = "androidx.appcompat.app.AppCompatDelegate.application_locales_record_file"
            r2 = 0
            java.io.FileOutputStream r1 = r6.openFileOutput(r1, r2)     // Catch: java.io.FileNotFoundException -> L5f java.lang.Throwable -> L73
            org.xmlpull.v1.XmlSerializer r2 = android.util.Xml.newSerializer()     // Catch: java.lang.Throwable -> L73
            r3 = 0
            r2.setOutput(r1, r3)     // Catch: java.lang.Throwable -> L41 java.lang.Exception -> L43
            java.lang.String r4 = "UTF-8"
            r5 = 1
            java.lang.Boolean r5 = java.lang.Boolean.valueOf(r5)     // Catch: java.lang.Throwable -> L41 java.lang.Exception -> L43
            r2.startDocument(r4, r5)     // Catch: java.lang.Throwable -> L41 java.lang.Exception -> L43
            java.lang.String r4 = "locales"
            r2.startTag(r3, r4)     // Catch: java.lang.Throwable -> L41 java.lang.Exception -> L43
            java.lang.String r4 = "application_locales"
            r2.attribute(r3, r4, r7)     // Catch: java.lang.Throwable -> L41 java.lang.Exception -> L43
            java.lang.String r4 = "locales"
            r2.endTag(r3, r4)     // Catch: java.lang.Throwable -> L41 java.lang.Exception -> L43
            r2.endDocument()     // Catch: java.lang.Throwable -> L41 java.lang.Exception -> L43
            if (r1 == 0) goto L54
            goto L4e
        L41:
            r3 = move-exception
            goto L56
        L43:
            r3 = move-exception
            java.lang.String r4 = "AppLocalesStorageHelper"
            java.lang.String r5 = "Storing App Locales : Failed to persist app-locales in storage "
            android.util.Log.w(r4, r5, r3)     // Catch: java.lang.Throwable -> L41
            if (r1 == 0) goto L54
        L4e:
            r1.close()     // Catch: java.io.IOException -> L52 java.lang.Throwable -> L73
        L51:
            goto L54
        L52:
            r3 = move-exception
            goto L51
        L54:
            monitor-exit(r0)     // Catch: java.lang.Throwable -> L73
            return
        L56:
            if (r1 == 0) goto L5d
            r1.close()     // Catch: java.io.IOException -> L5c java.lang.Throwable -> L73
            goto L5d
        L5c:
            r4 = move-exception
        L5d:
            throw r3     // Catch: java.lang.Throwable -> L73
        L5f:
            r1 = move-exception
            java.lang.String r2 = "AppLocalesStorageHelper"
            java.lang.String r3 = "Storing App Locales : FileNotFoundException: Cannot open file %s for writing "
            java.lang.String r4 = "androidx.appcompat.app.AppCompatDelegate.application_locales_record_file"
            java.lang.Object[] r4 = new java.lang.Object[]{r4}     // Catch: java.lang.Throwable -> L73
            java.lang.String r3 = java.lang.String.format(r3, r4)     // Catch: java.lang.Throwable -> L73
            android.util.Log.w(r2, r3)     // Catch: java.lang.Throwable -> L73
            monitor-exit(r0)     // Catch: java.lang.Throwable -> L73
            return
        L73:
            r1 = move-exception
            monitor-exit(r0)     // Catch: java.lang.Throwable -> L73
            throw r1
        */
        throw new UnsupportedOperationException("Method not decompiled: androidx.core.app.AppLocalesStorageHelper.persistLocales(android.content.Context, java.lang.String):void");
    }
}
