class AgoraUserModel {
  String name;
  bool isOnStage;
  bool muted;
  int uid;

  AgoraUserModel({
    required this.name,
    required this.muted,
    required this.uid,
    required this.isOnStage,
  });

  AgoraUserModel copyWith({
    String? name,
    bool? isOnStage,
    bool? muted,
    int? uid,
  }) {
    return AgoraUserModel(
      name: name ?? this.name,
      muted: muted ?? this.muted,
      uid: uid ?? this.uid,
      isOnStage: isOnStage ?? this.isOnStage,
    );
  }
}
