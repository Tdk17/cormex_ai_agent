class ConversationFilters {
  const ConversationFilters({
    this.search = '',
    this.channel,
    this.status,
    this.assignedUserId,
  });

  final String search;
  final String? channel;
  final String? status;
  final String? assignedUserId;

  ConversationFilters copyWith({
    String? search,
    String? channel,
    String? status,
    String? assignedUserId,
    bool clearChannel = false,
    bool clearStatus = false,
    bool clearAssignedUser = false,
  }) {
    return ConversationFilters(
      search: search ?? this.search,
      channel: clearChannel ? null : channel ?? this.channel,
      status: clearStatus ? null : status ?? this.status,
      assignedUserId: clearAssignedUser
          ? null
          : assignedUserId ?? this.assignedUserId,
    );
  }

  Map<String, dynamic> toParameters() {
    return <String, dynamic>{
      if (search.trim().isNotEmpty) 'search': search.trim(),
      if (channel != null) 'channel': channel,
      if (status != null) 'status': status,
      if (assignedUserId != null) 'assignedUserId': assignedUserId,
    };
  }
}
