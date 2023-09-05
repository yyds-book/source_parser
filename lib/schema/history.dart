import 'package:isar/isar.dart';

part 'history.g.dart';

@Collection(accessor: 'histories')
@Name('histories')
class History {
  Id id = Isar.autoIncrement;
  String author = '';
  String catalogueUrl = '';
  String category = '';
  List<Catalogue> chapters = [];
  String cover = '';
  int cursor = 0;
  int index = 0;
  String introduction = '';
  @Name('latest_chapter')
  String latestChapter = '';
  String name = '';
  @Name('source_id')
  int sourceId = 0;
  @Name('sources')
  List<SourceSwitcher> sources = [];
  String status = '';
  @Name('updated_at')
  String updatedAt = '';
  String url = '';
  String words = '';

  History();

  factory History.fromJson(Map<String, dynamic> json) {
    List<Catalogue> chapters = [];
    if (json['chapters'] is List) {
      chapters = (json['chapters'] as List)
          .map((chapter) => Catalogue.fromJson(chapter))
          .toList();
    }
    List<SourceSwitcher> sources = [];
    if (json['sources'] is List) {
      sources = (json['sources'] as List)
          .map((source) => SourceSwitcher.fromJson(source))
          .toList();
    }
    return History()
      ..author = json['author'] as String
      ..catalogueUrl = json['catalogue_url'] as String
      ..category = json['category'] as String
      ..chapters = chapters
      ..cover = json['cover'] as String
      ..cursor = json['cursor'] ?? 0
      ..index = json['index'] ?? 0
      ..introduction = json['introduction'] as String
      ..latestChapter = json['latest_chapter'] as String
      ..name = json['name'] as String
      ..sourceId = json['source_id'] as int
      ..sources = sources
      ..status = json['status'] as String
      ..updatedAt = json['updated_at'] as String
      ..url = json['url'] as String
      ..words = json['words'] as String;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author': author,
      'catalogue_url': catalogueUrl,
      'category': category,
      'chapters': chapters.map((chapter) => chapter.toJson()).toList(),
      'cover': cover,
      'cursor': cursor,
      'index': index,
      'introduction': introduction,
      'latest_chapter': latestChapter,
      'name': name,
      'source_id': sourceId,
      'sources': sources.map((source) => source.toJson()).toList(),
      'status': status,
      'updated_at': updatedAt,
      'url': url,
      'words': words,
    };
  }

  @override
  String toString() {
    return toJson().toString();
  }
}

@embedded
@Name('catalogues')
class Catalogue {
  String name = '';
  String url = '';

  Catalogue();

  factory Catalogue.fromJson(Map<String, dynamic> json) {
    return Catalogue()
      ..name = json['name'] as String
      ..url = json['url'] as String;
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'url': url};
  }

  @override
  String toString() {
    return toJson().toString();
  }
}

@embedded
@Name('source_switchers')
class SourceSwitcher {
  int id = 0;
  String name = '';
  String url = '';

  SourceSwitcher();

  factory SourceSwitcher.fromJson(Map<String, dynamic> json) {
    return SourceSwitcher()
      ..id = json['id'] as int
      ..name = json['name'] as String
      ..url = json['url'] as String;
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'url': url};
  }

  @override
  String toString() {
    return toJson().toString();
  }
}
