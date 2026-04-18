package com.google.android.gms.common.internal;

import android.content.Context;
import android.content.res.Resources;
import android.util.AttributeSet;
import android.util.Log;
import android.util.TypedValue;

/* JADX INFO: compiled from: com.google.android.gms:play-services-basement@@18.1.0 */
/* JADX INFO: loaded from: classes.dex */
public class ViewUtils {
    private ViewUtils() {
    }

    public static String getXmlAttributeString(String namespace, String name, Context context, AttributeSet attrs, boolean allowResources, boolean required, String logTag) {
        String attributeValue = attrs == null ? null : attrs.getAttributeValue(namespace, name);
        if (attributeValue != null && attributeValue.startsWith("@string/") && allowResources) {
            String strSubstring = attributeValue.substring(8);
            String packageName = context.getPackageName();
            TypedValue typedValue = new TypedValue();
            try {
                context.getResources().getValue(packageName + ":string/" + strSubstring, typedValue, true);
            } catch (Resources.NotFoundException e) {
                Log.w(logTag, "Could not find resource for " + name + ": " + attributeValue);
            }
            if (typedValue.string != null) {
                attributeValue = typedValue.string.toString();
            } else {
                Log.w(logTag, "Resource " + name + " was not a string: " + typedValue.toString());
            }
        }
        if (required && attributeValue == null) {
            Log.w(logTag, "Required XML attribute \"" + name + "\" missing");
        }
        return attributeValue;
    }
}
