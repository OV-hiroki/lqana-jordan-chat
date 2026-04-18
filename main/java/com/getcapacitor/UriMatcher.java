package com.getcapacitor;

import androidx.webkit.ProxyConfig;
import java.util.ArrayList;
import java.util.regex.Pattern;

/* JADX INFO: loaded from: classes3.dex */
public class UriMatcher {
    private static final int EXACT = 0;
    private static final int MASK = 3;
    static final Pattern PATH_SPLIT_PATTERN = Pattern.compile("/");
    private static final int REST = 2;
    private static final int TEXT = 1;
    private ArrayList<UriMatcher> mChildren;
    private Object mCode;
    private String mText;
    private int mWhich;

    public UriMatcher(Object code) {
        this.mCode = code;
        this.mWhich = -1;
        this.mChildren = new ArrayList<>();
        this.mText = null;
    }

    private UriMatcher() {
        this.mCode = null;
        this.mWhich = -1;
        this.mChildren = new ArrayList<>();
        this.mText = null;
    }

    public void addURI(String scheme, String authority, String path, Object code) {
        String token;
        if (code == null) {
            throw new IllegalArgumentException("Code can't be null");
        }
        String[] tokens = null;
        if (path != null) {
            String newPath = path;
            if (!path.isEmpty() && path.charAt(0) == '/') {
                newPath = path.substring(1);
            }
            tokens = PATH_SPLIT_PATTERN.split(newPath);
        }
        int numTokens = tokens != null ? tokens.length : 0;
        UriMatcher node = this;
        int i = -2;
        while (i < numTokens) {
            if (i == -2) {
                token = scheme;
            } else {
                token = i == -1 ? authority : tokens[i];
            }
            ArrayList<UriMatcher> children = node.mChildren;
            int numChildren = children.size();
            int j = 0;
            while (true) {
                if (j >= numChildren) {
                    break;
                }
                UriMatcher child = children.get(j);
                if (!token.equals(child.mText)) {
                    j++;
                } else {
                    node = child;
                    break;
                }
            }
            if (j == numChildren) {
                UriMatcher child2 = new UriMatcher();
                if (i == -1 && token.contains(ProxyConfig.MATCH_ALL_SCHEMES)) {
                    child2.mWhich = 3;
                } else if (token.equals("**")) {
                    child2.mWhich = 2;
                } else if (token.equals(ProxyConfig.MATCH_ALL_SCHEMES)) {
                    child2.mWhich = 1;
                } else {
                    child2.mWhich = 0;
                }
                child2.mText = token;
                node.mChildren.add(child2);
                node = child2;
            }
            i++;
        }
        node.mCode = code;
    }

    /* JADX WARN: Can't fix incorrect switch cases order, some code will duplicate */
    /* JADX WARN: Removed duplicated region for block: B:36:0x0065 A[LOOP:1: B:21:0x0038->B:36:0x0065, LOOP_END] */
    /* JADX WARN: Removed duplicated region for block: B:40:0x006c A[LOOP:0: B:9:0x0015->B:40:0x006c, LOOP_END] */
    /* JADX WARN: Removed duplicated region for block: B:46:0x006a A[SYNTHETIC] */
    /* JADX WARN: Removed duplicated region for block: B:47:0x0068 A[SYNTHETIC] */
    /*
        Code decompiled incorrectly, please refer to instructions dump.
        To view partially-correct code enable 'Show inconsistent code' option in preferences
    */
    public java.lang.Object match(android.net.Uri r11) {
        /*
            r10 = this;
            java.util.List r0 = r11.getPathSegments()
            int r1 = r0.size()
            r2 = r10
            if (r1 != 0) goto L14
            java.lang.String r3 = r11.getAuthority()
            if (r3 != 0) goto L14
            java.lang.Object r3 = r10.mCode
            return r3
        L14:
            r3 = -2
        L15:
            if (r3 >= r1) goto L6f
            r4 = -2
            if (r3 != r4) goto L1f
            java.lang.String r4 = r11.getScheme()
            goto L2d
        L1f:
            r4 = -1
            if (r3 != r4) goto L27
            java.lang.String r4 = r11.getAuthority()
            goto L2d
        L27:
            java.lang.Object r4 = r0.get(r3)
            java.lang.String r4 = (java.lang.String) r4
        L2d:
            java.util.ArrayList<com.getcapacitor.UriMatcher> r5 = r2.mChildren
            if (r5 != 0) goto L32
            goto L6f
        L32:
            r2 = 0
            int r6 = r5.size()
            r7 = 0
        L38:
            if (r7 >= r6) goto L68
            java.lang.Object r8 = r5.get(r7)
            com.getcapacitor.UriMatcher r8 = (com.getcapacitor.UriMatcher) r8
            int r9 = r8.mWhich
            switch(r9) {
                case 0: goto L59;
                case 1: goto L57;
                case 2: goto L54;
                case 3: goto L46;
                default: goto L45;
            }
        L45:
            goto L62
        L46:
            java.lang.String r9 = r8.mText
            com.getcapacitor.util.HostMask r9 = com.getcapacitor.util.HostMask.Parser.parse(r9)
            boolean r9 = r9.matches(r4)
            if (r9 == 0) goto L62
            r2 = r8
            goto L62
        L54:
            java.lang.Object r9 = r8.mCode
            return r9
        L57:
            r2 = r8
            goto L62
        L59:
            java.lang.String r9 = r8.mText
            boolean r9 = r9.equals(r4)
            if (r9 == 0) goto L62
            r2 = r8
        L62:
            if (r2 == 0) goto L65
            goto L68
        L65:
            int r7 = r7 + 1
            goto L38
        L68:
            if (r2 != 0) goto L6c
            r7 = 0
            return r7
        L6c:
            int r3 = r3 + 1
            goto L15
        L6f:
            java.lang.Object r3 = r2.mCode
            return r3
        */
        throw new UnsupportedOperationException("Method not decompiled: com.getcapacitor.UriMatcher.match(android.net.Uri):java.lang.Object");
    }
}
