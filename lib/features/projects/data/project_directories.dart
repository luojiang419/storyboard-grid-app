import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../core/services/workspace_directories.dart';

class ProjectDirectories implements WorkspaceDirectories {
  const ProjectDirectories({
    required this.root,
    required this.imports,
    required this.cuts,
    required this.storyboards,
    required this.storyboardFolders,
    required this.generatedImages,
    required this.exports,
    required this.database,
    required this.temp,
    required this.logs,
  });

  final Directory root;
  @override
  final Directory imports;
  @override
  final Directory cuts;
  @override
  final Directory storyboards;
  @override
  final Directory storyboardFolders;
  @override
  final Directory generatedImages;
  @override
  final Directory exports;
  @override
  final Directory database;
  @override
  final Directory temp;
  @override
  final Directory logs;

  @override
  Directory get workspaceRoot => root;

  File get indexFile => File(p.join(root.path, 'project.storyboard'));
  @override
  File get databaseFile => File(p.join(database.path, 'project.sqlite'));
  File get lockFile => File(p.join(database.path, 'project.lock'));

  List<Directory> get managedDirectories => [
    database,
    imports,
    cuts,
    storyboards,
    storyboardFolders,
    generatedImages,
    exports,
    temp,
    logs,
  ];

  factory ProjectDirectories.fromRoot(Directory root) {
    final storyboards = Directory(p.join(root.path, 'storyboards'));
    return ProjectDirectories(
      root: root,
      imports: Directory(p.join(root.path, 'imports')),
      cuts: Directory(p.join(root.path, 'cuts')),
      storyboards: storyboards,
      storyboardFolders: Directory(p.join(storyboards.path, 'custom_folders')),
      generatedImages: Directory(p.join(root.path, 'generated_images')),
      exports: Directory(p.join(root.path, 'exports')),
      database: Directory(p.join(root.path, 'database')),
      temp: Directory(p.join(root.path, 'temp')),
      logs: Directory(p.join(root.path, 'logs')),
    );
  }

  Future<void> create() async {
    for (final directory in managedDirectories) {
      if (!directory.existsSync()) {
        await directory.create(recursive: true);
      }
    }
  }
}
