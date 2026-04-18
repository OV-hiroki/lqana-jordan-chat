package com.getcapacitor;

import android.content.ContentUris;
import android.content.Context;
import android.content.res.AssetManager;
import android.database.Cursor;
import android.net.Uri;
import android.os.Environment;
import android.provider.DocumentsContract;
import android.provider.MediaStore;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;

/* JADX INFO: loaded from: classes3.dex */
public class FileUtils {
    private static String CapacitorFileScheme = Bridge.CAPACITOR_FILE_START;

    public enum Type {
        IMAGE("image");

        private String type;

        Type(String type) {
            this.type = type;
        }
    }

    public static String getPortablePath(Context c, String host, Uri u) {
        String path = getFileUrlForUri(c, u);
        if (path.startsWith("file://")) {
            path = path.replace("file://", "");
        }
        return host + Bridge.CAPACITOR_FILE_START + path;
    }

    public static String getFileUrlForUri(Context context, Uri uri) {
        if (DocumentsContract.isDocumentUri(context, uri)) {
            if (isExternalStorageDocument(uri)) {
                String docId = DocumentsContract.getDocumentId(uri);
                String[] split = docId.split(":");
                if ("primary".equalsIgnoreCase(split[0])) {
                    return legacyPrimaryPath(split[1]);
                }
                int splitIndex = docId.indexOf(58, 1);
                String tag = docId.substring(0, splitIndex);
                String path = docId.substring(splitIndex + 1);
                String nonPrimaryVolume = getPathToNonPrimaryVolume(context, tag);
                if (nonPrimaryVolume != null) {
                    String result = nonPrimaryVolume + "/" + path;
                    File file = new File(result);
                    if (file.exists() && file.canRead()) {
                        return result;
                    }
                    return null;
                }
            } else {
                if (isDownloadsDocument(uri)) {
                    String id = DocumentsContract.getDocumentId(uri);
                    Uri contentUri = ContentUris.withAppendedId(Uri.parse("content://downloads/public_downloads"), Long.valueOf(id).longValue());
                    return getDataColumn(context, contentUri, null, null);
                }
                if (isMediaDocument(uri)) {
                    String[] split2 = DocumentsContract.getDocumentId(uri).split(":");
                    String type = split2[0];
                    Uri contentUri2 = null;
                    if ("image".equals(type)) {
                        contentUri2 = MediaStore.Images.Media.EXTERNAL_CONTENT_URI;
                    } else if ("video".equals(type)) {
                        contentUri2 = MediaStore.Video.Media.EXTERNAL_CONTENT_URI;
                    } else if ("audio".equals(type)) {
                        contentUri2 = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI;
                    }
                    String[] selectionArgs = {split2[1]};
                    return getDataColumn(context, contentUri2, "_id=?", selectionArgs);
                }
            }
        } else {
            if ("content".equalsIgnoreCase(uri.getScheme())) {
                return isGooglePhotosUri(uri) ? uri.getLastPathSegment() : getDataColumn(context, uri, null, null);
            }
            if ("file".equalsIgnoreCase(uri.getScheme())) {
                return uri.getPath();
            }
        }
        return null;
    }

    private static String legacyPrimaryPath(String pathPart) {
        return Environment.getExternalStorageDirectory() + "/" + pathPart;
    }

    static String readFileFromAssets(AssetManager assetManager, String fileName) throws IOException {
        BufferedReader reader = new BufferedReader(new InputStreamReader(assetManager.open(fileName)));
        try {
            StringBuilder buffer = new StringBuilder();
            while (true) {
                String line = reader.readLine();
                if (line != null) {
                    buffer.append(line).append("\n");
                } else {
                    String string = buffer.toString();
                    reader.close();
                    return string;
                }
            }
        } catch (Throwable th) {
            try {
                reader.close();
            } catch (Throwable th2) {
                th.addSuppressed(th2);
            }
            throw th;
        }
    }

    static String readFileFromDisk(File file) throws IOException {
        BufferedReader reader = new BufferedReader(new FileReader(file));
        try {
            StringBuilder buffer = new StringBuilder();
            while (true) {
                String line = reader.readLine();
                if (line != null) {
                    buffer.append(line).append("\n");
                } else {
                    String string = buffer.toString();
                    reader.close();
                    return string;
                }
            }
        } catch (Throwable th) {
            try {
                reader.close();
            } catch (Throwable th2) {
                th.addSuppressed(th2);
            }
            throw th;
        }
    }

    /* JADX WARN: Removed duplicated region for block: B:30:0x0055  */
    /* JADX WARN: Removed duplicated region for block: B:36:? A[SYNTHETIC] */
    /*
        Code decompiled incorrectly, please refer to instructions dump.
        To view partially-correct code enable 'Show inconsistent code' option in preferences
    */
    private static java.lang.String getDataColumn(android.content.Context r12, android.net.Uri r13, java.lang.String r14, java.lang.String[] r15) {
        /*
            r1 = 0
            r2 = 0
            java.lang.String r3 = "_data"
            r0 = 1
            java.lang.String[] r0 = new java.lang.String[r0]
            r4 = 0
            java.lang.String r5 = "_data"
            r0[r4] = r5
            r8 = r0
            android.content.ContentResolver r6 = r12.getContentResolver()     // Catch: java.lang.Throwable -> L3e java.lang.IllegalArgumentException -> L44
            r11 = 0
            r7 = r13
            r9 = r14
            r10 = r15
            android.database.Cursor r13 = r6.query(r7, r8, r9, r10, r11)     // Catch: java.lang.Throwable -> L38 java.lang.IllegalArgumentException -> L3b
            r2 = r13
            if (r2 == 0) goto L2b
            boolean r13 = r2.moveToFirst()     // Catch: java.lang.Throwable -> L38 java.lang.IllegalArgumentException -> L3b
            if (r13 == 0) goto L2b
            int r13 = r2.getColumnIndexOrThrow(r5)     // Catch: java.lang.Throwable -> L38 java.lang.IllegalArgumentException -> L3b
            java.lang.String r14 = r2.getString(r13)     // Catch: java.lang.Throwable -> L38 java.lang.IllegalArgumentException -> L3b
            r1 = r14
        L2b:
            if (r2 == 0) goto L30
            r2.close()
        L30:
            if (r1 != 0) goto L37
            java.lang.String r13 = getCopyFilePath(r7, r12)
            return r13
        L37:
            return r1
        L38:
            r0 = move-exception
            r13 = r0
            goto L53
        L3b:
            r0 = move-exception
            r13 = r0
            goto L49
        L3e:
            r0 = move-exception
            r7 = r13
            r9 = r14
            r10 = r15
            r13 = r0
            goto L53
        L44:
            r0 = move-exception
            r7 = r13
            r9 = r14
            r10 = r15
            r13 = r0
        L49:
            java.lang.String r14 = getCopyFilePath(r7, r12)     // Catch: java.lang.Throwable -> L38
            if (r2 == 0) goto L52
            r2.close()
        L52:
            return r14
        L53:
            if (r2 == 0) goto L58
            r2.close()
        L58:
            throw r13
        */
        throw new UnsupportedOperationException("Method not decompiled: com.getcapacitor.FileUtils.getDataColumn(android.content.Context, android.net.Uri, java.lang.String, java.lang.String[]):java.lang.String");
    }

    private static String getCopyFilePath(Uri uri, Context context) {
        Cursor cursor = context.getContentResolver().query(uri, null, null, null, null);
        int nameIndex = cursor.getColumnIndex("_display_name");
        cursor.moveToFirst();
        String name = cursor.getString(nameIndex);
        String fileName = sanitizeFilename(name);
        File file = new File(context.getFilesDir(), fileName);
        try {
            InputStream inputStream = context.getContentResolver().openInputStream(uri);
            FileOutputStream outputStream = new FileOutputStream(file);
            int bufferSize = Math.min(inputStream.available(), 1048576);
            byte[] buffers = new byte[bufferSize];
            while (true) {
                int read = inputStream.read(buffers);
                if (read == -1) {
                    break;
                }
                outputStream.write(buffers, 0, read);
            }
            inputStream.close();
            outputStream.close();
            if (cursor != null) {
                cursor.close();
            }
            return file.getPath();
        } catch (Exception e) {
            if (cursor != null) {
                cursor.close();
                return null;
            }
            return null;
        } catch (Throwable th) {
            if (cursor != null) {
                cursor.close();
            }
            throw th;
        }
    }

    private static boolean isExternalStorageDocument(Uri uri) {
        return "com.android.externalstorage.documents".equals(uri.getAuthority());
    }

    private static boolean isDownloadsDocument(Uri uri) {
        return "com.android.providers.downloads.documents".equals(uri.getAuthority());
    }

    private static boolean isMediaDocument(Uri uri) {
        return "com.android.providers.media.documents".equals(uri.getAuthority());
    }

    private static boolean isGooglePhotosUri(Uri uri) {
        return "com.google.android.apps.photos.content".equals(uri.getAuthority());
    }

    private static String getPathToNonPrimaryVolume(Context context, String tag) {
        String path;
        int index;
        File[] volumes = context.getExternalCacheDirs();
        if (volumes != null) {
            for (File volume : volumes) {
                if (volume != null && (path = volume.getAbsolutePath()) != null && (index = path.indexOf(tag)) != -1) {
                    return path.substring(0, index) + tag;
                }
            }
            return null;
        }
        return null;
    }

    private static String sanitizeFilename(String displayName) {
        String[] badCharacters = {"..", "/"};
        String[] segments = displayName.split("/");
        String fileName = segments[segments.length - 1];
        for (String suspString : badCharacters) {
            fileName = fileName.replace(suspString, "_");
        }
        return fileName;
    }
}
