class XpEvent {
  final String id;
  final String title;
  final String subtitle;
  final int xp;
  final DateTime date;

  XpEvent({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.xp,
    required this.date,
  });

  factory XpEvent.fromJson(Map<String, dynamic> json) {
    return XpEvent(
      id: json['id'],
      title: json['title'],
      subtitle: json['subtitle'],
      xp: json['xp'],
      date: DateTime.parse(json['createdAt']),
    );
  }
}
