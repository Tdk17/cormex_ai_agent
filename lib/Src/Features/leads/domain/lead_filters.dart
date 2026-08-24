class LeadFilters {
  const LeadFilters({
    this.search = '',
    this.status,
    this.source,
    this.tag,
  });

  final String search;
  final String? status;
  final String? source;
  final String? tag;

  bool get isEmpty =>
      search.trim().isEmpty && status == null && source == null && tag == null;

  int get activeCount => <bool>[
        status != null,
        source != null,
        tag != null,
      ].where((bool value) => value).length;

  Map<String, dynamic> toParameters() {
    return <String, dynamic>{
      if (search.trim().isNotEmpty) 'search': search.trim(),
      if (status != null) 'status': status,
      if (source != null) 'source': source,
      if (tag != null) 'tag': tag,
    };
  }

  LeadFilters copyWith({
    String? search,
    String? status,
    String? source,
    String? tag,
    bool clearStatus = false,
    bool clearSource = false,
    bool clearTag = false,
  }) {
    return LeadFilters(
      search: search ?? this.search,
      status: clearStatus ? null : status ?? this.status,
      source: clearSource ? null : source ?? this.source,
      tag: clearTag ? null : tag ?? this.tag,
    );
  }
}
