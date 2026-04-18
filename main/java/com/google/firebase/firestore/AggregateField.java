package com.google.firebase.firestore;

import java.util.Objects;

/* JADX INFO: loaded from: classes.dex */
public abstract class AggregateField {
    private final String alias;
    private final FieldPath fieldPath;
    private final String operator;

    private AggregateField(FieldPath fieldPath, String operator) {
        this.fieldPath = fieldPath;
        this.operator = operator;
        this.alias = operator + (fieldPath == null ? "" : "_" + fieldPath);
    }

    public String getFieldPath() {
        return this.fieldPath == null ? "" : this.fieldPath.toString();
    }

    public String getAlias() {
        return this.alias;
    }

    public String getOperator() {
        return this.operator;
    }

    public boolean equals(Object other) {
        if (this == other) {
            return true;
        }
        if (!(other instanceof AggregateField)) {
            return false;
        }
        AggregateField otherAggregateField = (AggregateField) other;
        return (this.fieldPath == null || otherAggregateField.fieldPath == null) ? this.fieldPath == null && otherAggregateField.fieldPath == null : this.operator.equals(otherAggregateField.getOperator()) && getFieldPath().equals(otherAggregateField.getFieldPath());
    }

    public int hashCode() {
        return Objects.hash(getOperator(), getFieldPath());
    }

    public static CountAggregateField count() {
        return new CountAggregateField();
    }

    public static SumAggregateField sum(String field) {
        return new SumAggregateField(FieldPath.fromDotSeparatedPath(field));
    }

    public static SumAggregateField sum(FieldPath fieldPath) {
        return new SumAggregateField(fieldPath);
    }

    public static AverageAggregateField average(String field) {
        return new AverageAggregateField(FieldPath.fromDotSeparatedPath(field));
    }

    public static AverageAggregateField average(FieldPath fieldPath) {
        return new AverageAggregateField(fieldPath);
    }

    public static class CountAggregateField extends AggregateField {
        private CountAggregateField() {
            super(null, "count");
        }
    }

    public static class SumAggregateField extends AggregateField {
        private SumAggregateField(FieldPath fieldPath) {
            super(fieldPath, "sum");
        }
    }

    public static class AverageAggregateField extends AggregateField {
        private AverageAggregateField(FieldPath fieldPath) {
            super(fieldPath, "average");
        }
    }
}
