const int _HASH_MASK = 0x7fffffff;

class ListEquality<E> implements Equality<List<E>> {
  final Equality<E> _elementEquality;
  const ListEquality([Equality<E> elementEquality = const DefaultEquality()])
      : _elementEquality = elementEquality;

  @override
  bool equals(List<E> list1, List<E> list2) {
    if (identical(list1, list2)) return true;

    var length = list1.length;
    if (length != list2.length) return false;
    for (var i = 0; i < length; i++) {
      if (!_elementEquality.equals(list1[i], list2[i])) return false;
    }
    return true;
  }

  @override
  int hash(List<E> list) {
    // Jenkins's one-at-a-time hash function.
    // This code is almost identical to the one in IterableEquality, except
    // that it uses indexing instead of iterating to get the elements.
    var hash = 0;
    for (var i = 0; i < list.length; i++) {
      var c = _elementEquality.hash(list[i]);
      hash = (hash + c) & _HASH_MASK;
      hash = (hash + (hash << 10)) & _HASH_MASK;
      hash ^= (hash >> 6);
    }
    hash = (hash + (hash << 3)) & _HASH_MASK;
    hash ^= (hash >> 11);
    hash = (hash + (hash << 15)) & _HASH_MASK;
    return hash;
  }

  @override
  bool isValidKey(Object o) => o is List<E>;
}

abstract class Equality<E> {
  const factory Equality() = DefaultEquality<E>;

  /// Compare two elements for being equal.
  ///
  /// This should be a proper equality relation.
  bool equals(E e1, E e2);

  /// Get a hashcode of an element.
  ///
  /// The hashcode should be compatible with [equals], so that if
  /// `equals(a, b)` then `hash(a) == hash(b)`.
  int hash(E e);

  /// Test whether an object is a valid argument to [equals] and [hash].
  ///
  /// Some implementations may be restricted to only work on specific types
  /// of objects.
  bool isValidKey(Object o);
}

class DefaultEquality<E> implements Equality<E> {
  const DefaultEquality();
  @override
  bool equals(Object? e1, Object? e2) => e1 == e2;
  @override
  int hash(Object? e) => e.hashCode;
  @override
  bool isValidKey(Object o) => true;
}
