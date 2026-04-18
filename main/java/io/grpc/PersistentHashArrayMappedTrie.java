package io.grpc;

import java.util.Arrays;

/* JADX INFO: loaded from: classes8.dex */
final class PersistentHashArrayMappedTrie {

    interface Node<K, V> {
        V get(K k, int i, int i2);

        Node<K, V> put(K k, V v, int i, int i2);

        int size();
    }

    private PersistentHashArrayMappedTrie() {
    }

    static <K, V> V get(Node<K, V> root, K key) {
        if (root == null) {
            return null;
        }
        return root.get(key, key.hashCode(), 0);
    }

    static <K, V> Node<K, V> put(Node<K, V> root, K key, V value) {
        if (root == null) {
            return new Leaf(key, value);
        }
        return root.put(key, value, key.hashCode(), 0);
    }

    static final class Leaf<K, V> implements Node<K, V> {
        private final K key;
        private final V value;

        public Leaf(K key, V value) {
            this.key = key;
            this.value = value;
        }

        @Override // io.grpc.PersistentHashArrayMappedTrie.Node
        public int size() {
            return 1;
        }

        @Override // io.grpc.PersistentHashArrayMappedTrie.Node
        public V get(K key, int hash, int bitsConsumed) {
            if (this.key == key) {
                return this.value;
            }
            return null;
        }

        @Override // io.grpc.PersistentHashArrayMappedTrie.Node
        public Node<K, V> put(K key, V value, int hash, int bitsConsumed) {
            int thisHash = this.key.hashCode();
            if (thisHash != hash) {
                return CompressedIndex.combine(new Leaf(key, value), hash, this, thisHash, bitsConsumed);
            }
            if (this.key == key) {
                return new Leaf(key, value);
            }
            return new CollisionLeaf(this.key, this.value, key, value);
        }

        public String toString() {
            return String.format("Leaf(key=%s value=%s)", this.key, this.value);
        }
    }

    static final class CollisionLeaf<K, V> implements Node<K, V> {
        static final /* synthetic */ boolean $assertionsDisabled = false;
        private final K[] keys;
        private final V[] values;

        CollisionLeaf(K key1, V value1, K key2, V value2) {
            this(new Object[]{key1, key2}, new Object[]{value1, value2});
            if (key1 == key2) {
                throw new AssertionError();
            }
            if (key1.hashCode() != key2.hashCode()) {
                throw new AssertionError();
            }
        }

        private CollisionLeaf(K[] keys, V[] values) {
            this.keys = keys;
            this.values = values;
        }

        @Override // io.grpc.PersistentHashArrayMappedTrie.Node
        public int size() {
            return this.values.length;
        }

        @Override // io.grpc.PersistentHashArrayMappedTrie.Node
        public V get(K key, int hash, int bitsConsumed) {
            for (int i = 0; i < this.keys.length; i++) {
                if (this.keys[i] == key) {
                    return this.values[i];
                }
            }
            return null;
        }

        @Override // io.grpc.PersistentHashArrayMappedTrie.Node
        public Node<K, V> put(K key, V value, int hash, int bitsConsumed) {
            int thisHash = this.keys[0].hashCode();
            if (thisHash != hash) {
                return CompressedIndex.combine(new Leaf(key, value), hash, this, thisHash, bitsConsumed);
            }
            int keyIndex = indexOfKey(key);
            if (keyIndex != -1) {
                Object[] objArrCopyOf = Arrays.copyOf(this.keys, this.keys.length);
                Object[] objArrCopyOf2 = Arrays.copyOf(this.values, this.keys.length);
                objArrCopyOf[keyIndex] = key;
                objArrCopyOf2[keyIndex] = value;
                return new CollisionLeaf(objArrCopyOf, objArrCopyOf2);
            }
            K[] newKeys = this.keys;
            Object[] objArrCopyOf3 = Arrays.copyOf(newKeys, this.keys.length + 1);
            Object[] objArrCopyOf4 = Arrays.copyOf(this.values, this.keys.length + 1);
            objArrCopyOf3[this.keys.length] = key;
            objArrCopyOf4[this.keys.length] = value;
            return new CollisionLeaf(objArrCopyOf3, objArrCopyOf4);
        }

        private int indexOfKey(K key) {
            for (int i = 0; i < this.keys.length; i++) {
                if (this.keys[i] == key) {
                    return i;
                }
            }
            return -1;
        }

        public String toString() {
            StringBuilder valuesSb = new StringBuilder();
            valuesSb.append("CollisionLeaf(");
            for (int i = 0; i < this.values.length; i++) {
                valuesSb.append("(key=").append(this.keys[i]).append(" value=").append(this.values[i]).append(") ");
            }
            return valuesSb.append(")").toString();
        }
    }

    static final class CompressedIndex<K, V> implements Node<K, V> {
        static final /* synthetic */ boolean $assertionsDisabled = false;
        private static final int BITS = 5;
        private static final int BITS_MASK = 31;
        final int bitmap;
        private final int size;
        final Node<K, V>[] values;

        private CompressedIndex(int bitmap, Node<K, V>[] values, int size) {
            this.bitmap = bitmap;
            this.values = values;
            this.size = size;
        }

        @Override // io.grpc.PersistentHashArrayMappedTrie.Node
        public int size() {
            return this.size;
        }

        @Override // io.grpc.PersistentHashArrayMappedTrie.Node
        public V get(K key, int hash, int bitsConsumed) {
            int indexBit = indexBit(hash, bitsConsumed);
            if ((this.bitmap & indexBit) == 0) {
                return null;
            }
            int compressedIndex = compressedIndex(indexBit);
            return this.values[compressedIndex].get(key, hash, bitsConsumed + 5);
        }

        @Override // io.grpc.PersistentHashArrayMappedTrie.Node
        public Node<K, V> put(K key, V value, int hash, int bitsConsumed) {
            int indexBit = indexBit(hash, bitsConsumed);
            int compressedIndex = compressedIndex(indexBit);
            if ((this.bitmap & indexBit) == 0) {
                int newBitmap = this.bitmap | indexBit;
                Node<K, V>[] newValues = new Node[this.values.length + 1];
                System.arraycopy(this.values, 0, newValues, 0, compressedIndex);
                newValues[compressedIndex] = new Leaf<>(key, value);
                System.arraycopy(this.values, compressedIndex, newValues, compressedIndex + 1, this.values.length - compressedIndex);
                return new CompressedIndex(newBitmap, newValues, size() + 1);
            }
            Node<K, V>[] newValues2 = (Node[]) Arrays.copyOf(this.values, this.values.length);
            newValues2[compressedIndex] = this.values[compressedIndex].put(key, value, hash, bitsConsumed + 5);
            int newSize = size();
            return new CompressedIndex(this.bitmap, newValues2, (newSize + newValues2[compressedIndex].size()) - this.values[compressedIndex].size());
        }

        static <K, V> Node<K, V> combine(Node<K, V> node1, int hash1, Node<K, V> node2, int hash2, int bitsConsumed) {
            if (hash1 == hash2) {
                throw new AssertionError();
            }
            int indexBit1 = indexBit(hash1, bitsConsumed);
            int indexBit2 = indexBit(hash2, bitsConsumed);
            if (indexBit1 == indexBit2) {
                Node<K, V> node = combine(node1, hash1, node2, hash2, bitsConsumed + 5);
                Node<K, V>[] values = {node};
                return new CompressedIndex(indexBit1, values, node.size());
            }
            if (uncompressedIndex(hash1, bitsConsumed) > uncompressedIndex(hash2, bitsConsumed)) {
                node1 = node2;
                node2 = node1;
            }
            Node<K, V>[] values2 = {node1, node2};
            return new CompressedIndex(indexBit1 | indexBit2, values2, node1.size() + node2.size());
        }

        public String toString() {
            StringBuilder valuesSb = new StringBuilder();
            valuesSb.append("CompressedIndex(").append(String.format("bitmap=%s ", Integer.toBinaryString(this.bitmap)));
            for (Node<K, V> value : this.values) {
                valuesSb.append(value).append(" ");
            }
            return valuesSb.append(")").toString();
        }

        private int compressedIndex(int indexBit) {
            return Integer.bitCount(this.bitmap & (indexBit - 1));
        }

        private static int uncompressedIndex(int hash, int bitsConsumed) {
            return (hash >>> bitsConsumed) & 31;
        }

        private static int indexBit(int hash, int bitsConsumed) {
            int uncompressedIndex = uncompressedIndex(hash, bitsConsumed);
            return 1 << uncompressedIndex;
        }
    }
}
