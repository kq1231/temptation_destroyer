import 'package:objectbox/objectbox.dart';

@Entity()
class HadithModel {
  @Id()
  int id;

  String text;
  String narrator;
  String source;
  String reference;
  String? translation;
  String? explanation;
  bool isFavorite;

  @Property(type: PropertyType.date)
  DateTime? lastShownDate;

  HadithModel({
    this.id = 0,
    required this.text,
    required this.narrator,
    required this.source,
    required this.reference,
    this.translation,
    this.explanation,
    this.isFavorite = false,
    this.lastShownDate,
  });

  HadithModel copyWith({
    int? id,
    String? text,
    String? narrator,
    String? source,
    String? reference,
    String? translation,
    String? explanation,
    bool? isFavorite,
    DateTime? lastShownDate,
  }) {
    return HadithModel(
      id: id ?? this.id,
      text: text ?? this.text,
      narrator: narrator ?? this.narrator,
      source: source ?? this.source,
      reference: reference ?? this.reference,
      translation: translation ?? this.translation,
      explanation: explanation ?? this.explanation,
      isFavorite: isFavorite ?? this.isFavorite,
      lastShownDate: lastShownDate ?? this.lastShownDate,
    );
  }
}
