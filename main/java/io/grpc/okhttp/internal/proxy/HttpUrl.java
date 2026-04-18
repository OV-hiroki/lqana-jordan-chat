package io.grpc.okhttp.internal.proxy;

import io.grpc.internal.GrpcUtil;
import java.io.EOFException;
import java.net.IDN;
import java.net.InetAddress;
import java.util.Locale;
import okio.Buffer;

/* JADX INFO: loaded from: classes8.dex */
public final class HttpUrl {
    private static final char[] HEX_DIGITS = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'};
    private final String host;
    private final int port;
    private final String scheme;
    private final String url;

    private HttpUrl(Builder builder) {
        this.scheme = builder.scheme;
        this.host = builder.host;
        this.port = builder.effectivePort();
        this.url = builder.toString();
    }

    public String scheme() {
        return this.scheme;
    }

    public boolean isHttps() {
        return this.scheme.equals("https");
    }

    public String host() {
        return this.host;
    }

    public int port() {
        return this.port;
    }

    public static int defaultPort(String scheme) {
        if (scheme.equals("http")) {
            return 80;
        }
        if (scheme.equals("https")) {
            return GrpcUtil.DEFAULT_PORT_SSL;
        }
        return -1;
    }

    public Builder newBuilder() {
        Builder result = new Builder();
        result.scheme = this.scheme;
        result.host = this.host;
        result.port = this.port != defaultPort(this.scheme) ? this.port : -1;
        return result;
    }

    public boolean equals(Object o) {
        return (o instanceof HttpUrl) && ((HttpUrl) o).url.equals(this.url);
    }

    public int hashCode() {
        return this.url.hashCode();
    }

    public String toString() {
        return this.url;
    }

    public static final class Builder {
        String host;
        int port = -1;
        String scheme;

        public Builder scheme(String scheme) {
            if (scheme == null) {
                throw new IllegalArgumentException("scheme == null");
            }
            if (scheme.equalsIgnoreCase("http")) {
                this.scheme = "http";
            } else if (scheme.equalsIgnoreCase("https")) {
                this.scheme = "https";
            } else {
                throw new IllegalArgumentException("unexpected scheme: " + scheme);
            }
            return this;
        }

        public Builder host(String host) {
            if (host == null) {
                throw new IllegalArgumentException("host == null");
            }
            String encoded = canonicalizeHost(host, 0, host.length());
            if (encoded == null) {
                throw new IllegalArgumentException("unexpected host: " + host);
            }
            this.host = encoded;
            return this;
        }

        public Builder port(int port) {
            if (port <= 0 || port > 65535) {
                throw new IllegalArgumentException("unexpected port: " + port);
            }
            this.port = port;
            return this;
        }

        int effectivePort() {
            return this.port != -1 ? this.port : HttpUrl.defaultPort(this.scheme);
        }

        public HttpUrl build() {
            if (this.scheme == null) {
                throw new IllegalStateException("scheme == null");
            }
            if (this.host == null) {
                throw new IllegalStateException("host == null");
            }
            return new HttpUrl(this);
        }

        public String toString() {
            StringBuilder result = new StringBuilder();
            result.append(this.scheme);
            result.append("://");
            if (this.host.indexOf(58) != -1) {
                result.append('[');
                result.append(this.host);
                result.append(']');
            } else {
                result.append(this.host);
            }
            int effectivePort = effectivePort();
            if (effectivePort != HttpUrl.defaultPort(this.scheme)) {
                result.append(':');
                result.append(effectivePort);
            }
            return result.toString();
        }

        private static String canonicalizeHost(String input, int pos, int limit) {
            String percentDecoded = HttpUrl.percentDecode(input, pos, limit, false);
            if (percentDecoded.startsWith("[") && percentDecoded.endsWith("]")) {
                InetAddress inetAddress = decodeIpv6(percentDecoded, 1, percentDecoded.length() - 1);
                if (inetAddress == null) {
                    return null;
                }
                byte[] address = inetAddress.getAddress();
                if (address.length == 16) {
                    return inet6AddressToAscii(address);
                }
                throw new AssertionError();
            }
            return domainToAscii(percentDecoded);
        }

        /* JADX WARN: Code restructure failed: missing block: B:41:0x007c, code lost:
        
            r4 = r0.length;
         */
        /* JADX WARN: Code restructure failed: missing block: B:42:0x007d, code lost:
        
            if (r1 == r4) goto L51;
         */
        /* JADX WARN: Code restructure failed: missing block: B:43:0x007f, code lost:
        
            if (r2 != (-1)) goto L45;
         */
        /* JADX WARN: Code restructure failed: missing block: B:44:0x0081, code lost:
        
            return null;
         */
        /* JADX WARN: Code restructure failed: missing block: B:45:0x0082, code lost:
        
            java.lang.System.arraycopy(r0, r2, r0, r0.length - (r1 - r2), r1 - r2);
            java.util.Arrays.fill(r0, r2, (r0.length - r1) + r2, (byte) 0);
         */
        /* JADX WARN: Code restructure failed: missing block: B:47:0x0095, code lost:
        
            return java.net.InetAddress.getByAddress(r0);
         */
        /* JADX WARN: Code restructure failed: missing block: B:50:0x009c, code lost:
        
            throw new java.lang.AssertionError();
         */
        /* JADX WARN: Removed duplicated region for block: B:30:0x0050  */
        /*
            Code decompiled incorrectly, please refer to instructions dump.
            To view partially-correct code enable 'Show inconsistent code' option in preferences
        */
        private static java.net.InetAddress decodeIpv6(java.lang.String r11, int r12, int r13) {
            /*
                r0 = 16
                byte[] r0 = new byte[r0]
                r1 = 0
                r2 = -1
                r3 = -1
                r4 = r12
            L8:
                r5 = -1
                r6 = 0
                r7 = 0
                if (r4 >= r13) goto L7c
                int r8 = r0.length
                if (r1 != r8) goto L11
                return r7
            L11:
                int r8 = r4 + 2
                if (r8 > r13) goto L29
                java.lang.String r8 = "::"
                r9 = 2
                boolean r8 = r11.regionMatches(r4, r8, r6, r9)
                if (r8 == 0) goto L29
                if (r2 == r5) goto L21
                return r7
            L21:
                int r4 = r4 + 2
                int r1 = r1 + 2
                r2 = r1
                if (r4 != r13) goto L4c
                goto L7c
            L29:
                if (r1 == 0) goto L4c
                java.lang.String r8 = ":"
                r9 = 1
                boolean r8 = r11.regionMatches(r4, r8, r6, r9)
                if (r8 == 0) goto L37
                int r4 = r4 + 1
                goto L4c
            L37:
                java.lang.String r8 = "."
                boolean r8 = r11.regionMatches(r4, r8, r6, r9)
                if (r8 == 0) goto L4b
                int r8 = r1 + (-2)
                boolean r8 = decodeIpv4Suffix(r11, r3, r13, r0, r8)
                if (r8 != 0) goto L48
                return r7
            L48:
                int r1 = r1 + 2
                goto L7c
            L4b:
                return r7
            L4c:
                r6 = 0
                r3 = r4
            L4e:
                if (r4 >= r13) goto L62
                char r8 = r11.charAt(r4)
                int r9 = io.grpc.okhttp.internal.proxy.HttpUrl.decodeHexDigit(r8)
                if (r9 != r5) goto L5b
                goto L62
            L5b:
                int r10 = r6 << 4
                int r6 = r10 + r9
                int r4 = r4 + 1
                goto L4e
            L62:
                int r5 = r4 - r3
                if (r5 == 0) goto L7b
                r8 = 4
                if (r5 <= r8) goto L6a
                goto L7b
            L6a:
                int r7 = r1 + 1
                int r8 = r6 >>> 8
                r8 = r8 & 255(0xff, float:3.57E-43)
                byte r8 = (byte) r8
                r0[r1] = r8
                int r1 = r7 + 1
                r8 = r6 & 255(0xff, float:3.57E-43)
                byte r8 = (byte) r8
                r0[r7] = r8
                goto L8
            L7b:
                return r7
            L7c:
                int r4 = r0.length
                if (r1 == r4) goto L91
                if (r2 != r5) goto L82
                return r7
            L82:
                int r4 = r0.length
                int r5 = r1 - r2
                int r4 = r4 - r5
                int r5 = r1 - r2
                java.lang.System.arraycopy(r0, r2, r0, r4, r5)
                int r4 = r0.length
                int r4 = r4 - r1
                int r4 = r4 + r2
                java.util.Arrays.fill(r0, r2, r4, r6)
            L91:
                java.net.InetAddress r4 = java.net.InetAddress.getByAddress(r0)     // Catch: java.net.UnknownHostException -> L96
                return r4
            L96:
                r4 = move-exception
                java.lang.AssertionError r5 = new java.lang.AssertionError
                r5.<init>()
                throw r5
            */
            throw new UnsupportedOperationException("Method not decompiled: io.grpc.okhttp.internal.proxy.HttpUrl.Builder.decodeIpv6(java.lang.String, int, int):java.net.InetAddress");
        }

        private static boolean decodeIpv4Suffix(String input, int pos, int limit, byte[] address, int addressOffset) {
            int b = addressOffset;
            int i = pos;
            while (i < limit) {
                if (b == address.length) {
                    return false;
                }
                if (b != addressOffset) {
                    if (input.charAt(i) != '.') {
                        return false;
                    }
                    i++;
                }
                int value = 0;
                int groupOffset = i;
                while (i < limit) {
                    char c = input.charAt(i);
                    if (c < '0' || c > '9') {
                        break;
                    }
                    if ((value == 0 && groupOffset != i) || ((value * 10) + c) - 48 > 255) {
                        return false;
                    }
                    i++;
                }
                int groupLength = i - groupOffset;
                if (groupLength == 0) {
                    return false;
                }
                address[b] = (byte) value;
                b++;
            }
            int i2 = addressOffset + 4;
            return b == i2;
        }

        private static String domainToAscii(String input) {
            try {
                String result = IDN.toASCII(input).toLowerCase(Locale.US);
                if (result.isEmpty()) {
                    return null;
                }
                if (containsInvalidHostnameAsciiCodes(result)) {
                    return null;
                }
                return result;
            } catch (IllegalArgumentException e) {
                return null;
            }
        }

        private static boolean containsInvalidHostnameAsciiCodes(String hostnameAscii) {
            for (int i = 0; i < hostnameAscii.length(); i++) {
                char c = hostnameAscii.charAt(i);
                if (c <= 31 || c >= 127 || " #%/:?@[\\]".indexOf(c) != -1) {
                    return true;
                }
            }
            return false;
        }

        private static String inet6AddressToAscii(byte[] address) {
            int longestRunOffset = -1;
            int longestRunLength = 0;
            int i = 0;
            while (i < address.length) {
                int currentRunOffset = i;
                while (i < 16 && address[i] == 0 && address[i + 1] == 0) {
                    i += 2;
                }
                int currentRunLength = i - currentRunOffset;
                if (currentRunLength > longestRunLength) {
                    longestRunOffset = currentRunOffset;
                    longestRunLength = currentRunLength;
                }
                i += 2;
            }
            Buffer result = new Buffer();
            int i2 = 0;
            while (i2 < address.length) {
                if (i2 == longestRunOffset) {
                    result.writeByte(58);
                    i2 += longestRunLength;
                    if (i2 == 16) {
                        result.writeByte(58);
                    }
                } else {
                    if (i2 > 0) {
                        result.writeByte(58);
                    }
                    int group = ((address[i2] & 255) << 8) | (address[i2 + 1] & 255);
                    result.writeHexadecimalUnsignedLong(group);
                    i2 += 2;
                }
            }
            return result.readUtf8();
        }
    }

    static String percentDecode(String encoded, int pos, int limit, boolean plusIsSpace) {
        for (int i = pos; i < limit; i++) {
            char c = encoded.charAt(i);
            if (c == '%' || (c == '+' && plusIsSpace)) {
                Buffer out = new Buffer();
                out.writeUtf8(encoded, pos, i);
                percentDecode(out, encoded, i, limit, plusIsSpace);
                return out.readUtf8();
            }
        }
        return encoded.substring(pos, limit);
    }

    /* JADX WARN: Removed duplicated region for block: B:16:0x003d  */
    /*
        Code decompiled incorrectly, please refer to instructions dump.
        To view partially-correct code enable 'Show inconsistent code' option in preferences
    */
    static void percentDecode(okio.Buffer r5, java.lang.String r6, int r7, int r8, boolean r9) {
        /*
            r0 = r7
        L1:
            if (r0 >= r8) goto L47
            int r1 = r6.codePointAt(r0)
            r2 = 37
            if (r1 != r2) goto L31
            int r2 = r0 + 2
            if (r2 >= r8) goto L31
            int r2 = r0 + 1
            char r2 = r6.charAt(r2)
            int r2 = decodeHexDigit(r2)
            int r3 = r0 + 2
            char r3 = r6.charAt(r3)
            int r3 = decodeHexDigit(r3)
            r4 = -1
            if (r2 == r4) goto L3d
            if (r3 == r4) goto L3d
            int r4 = r2 << 4
            int r4 = r4 + r3
            r5.writeByte(r4)
            int r0 = r0 + 2
            goto L41
        L31:
            r2 = 43
            if (r1 != r2) goto L3d
            if (r9 == 0) goto L3d
            r2 = 32
            r5.writeByte(r2)
            goto L41
        L3d:
            r5.writeUtf8CodePoint(r1)
        L41:
            int r2 = java.lang.Character.charCount(r1)
            int r0 = r0 + r2
            goto L1
        L47:
            return
        */
        throw new UnsupportedOperationException("Method not decompiled: io.grpc.okhttp.internal.proxy.HttpUrl.percentDecode(okio.Buffer, java.lang.String, int, int, boolean):void");
    }

    static int decodeHexDigit(char c) {
        if (c >= '0' && c <= '9') {
            return c - '0';
        }
        if (c >= 'a' && c <= 'f') {
            return (c - 'a') + 10;
        }
        if (c < 'A' || c > 'F') {
            return -1;
        }
        return (c - 'A') + 10;
    }

    static void canonicalize(Buffer out, String input, int pos, int limit, String encodeSet, boolean alreadyEncoded, boolean plusIsSpace, boolean asciiOnly) {
        Buffer utf8Buffer = null;
        int i = pos;
        while (i < limit) {
            int codePoint = input.codePointAt(i);
            if (!alreadyEncoded || (codePoint != 9 && codePoint != 10 && codePoint != 12 && codePoint != 13)) {
                if (codePoint == 43 && plusIsSpace) {
                    out.writeUtf8(alreadyEncoded ? "+" : "%2B");
                } else if (codePoint < 32 || codePoint == 127 || ((codePoint >= 128 && asciiOnly) || encodeSet.indexOf(codePoint) != -1 || (codePoint == 37 && !alreadyEncoded))) {
                    if (utf8Buffer == null) {
                        utf8Buffer = new Buffer();
                    }
                    utf8Buffer.writeUtf8CodePoint(codePoint);
                    while (!utf8Buffer.exhausted()) {
                        try {
                            fakeEofExceptionMethod();
                            int b = utf8Buffer.readByte() & 255;
                            out.writeByte(37);
                            out.writeByte((int) HEX_DIGITS[(b >> 4) & 15]);
                            out.writeByte((int) HEX_DIGITS[b & 15]);
                        } catch (EOFException e) {
                            throw new IndexOutOfBoundsException(e.getMessage());
                        }
                    }
                } else {
                    out.writeUtf8CodePoint(codePoint);
                }
            }
            i += Character.charCount(codePoint);
        }
    }

    private static void fakeEofExceptionMethod() throws EOFException {
    }
}
