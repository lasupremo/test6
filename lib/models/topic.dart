class Topic {
  final String? id;
  final String text;
  final String? desc;
  final String? profileId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<Note>? notes;
  
  Topic({
    this.id, 
    required this.text, 
    this.desc,
    this.profileId,
    this.createdAt, 
    this.updatedAt,
    this.notes,
  });
  
  factory Topic.fromJson(Map<String, dynamic> json) => Topic(
    id: json['id'],
    text: json['text'],
    desc: json['desc'],
    profileId: json['profile_id'],
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    
    notes: json['notes'] != null 
        ? (json['notes'] as List).map((note) => Note.fromJson(note)).toList()
        : null,
  );
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'desc': desc,
    'profile_id': profileId,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}

class Note {
  final String? id;
  final String title;
  final String content;
  final String topicId;
  final String? userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  Note({
    this.id,
    required this.title,
    required this.content,
    required this.topicId,
    this.userId,
    this.createdAt,
    this.updatedAt,
  });
  
  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json['id'],
    title: json['title'],
    content: json['content'],
    topicId: json['topic_id'],
    userId: json['user_id'],
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
  );
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'topic_id': topicId,
    'user_id': userId,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}