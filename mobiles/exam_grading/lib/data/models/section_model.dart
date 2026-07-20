class SectionModel {
  String id;
  String sec;

  SectionModel({required this.id, required this.sec});

  factory SectionModel.fromMap(String id, Map<String, dynamic> map) {
    return SectionModel(
        id: id, sec: map['sec']?.toString() ?? map['code']?.toString() ?? '');
  }

  Map<String, dynamic> toMap() {
    return {'sec': sec};
  }
}
