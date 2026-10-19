import 'dart:convert';
import 'block.dart';
import 'gate.dart';

class LevelSolverData {
  final bool solvable;
  final int optimalMoves;
  final double branching;
  final int deadEnds;
  final double difficulty;

  const LevelSolverData({
    required this.solvable,
    required this.optimalMoves,
    required this.branching,
    required this.deadEnds,
    required this.difficulty,
  });

  factory LevelSolverData.fromJson(Map<String, dynamic> json) {
    return LevelSolverData(
      solvable: json['solvable'] as bool,
      optimalMoves: json['optimalMoves'] as int,
      branching: (json['branching'] as num).toDouble(),
      deadEnds: json['deadEnds'] as int,
      difficulty: (json['difficulty'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'solvable': solvable,
        'optimalMoves': optimalMoves,
        'branching': branching,
        'deadEnds': deadEnds,
        'difficulty': difficulty,
      };
}

class GridSize {
  final int width;
  final int height;

  const GridSize(this.width, this.height);

  factory GridSize.fromJson(Map<String, dynamic> json) {
    return GridSize(json['w'] as int, json['h'] as int);
  }

  Map<String, dynamic> toJson() => {'w': width, 'h': height};
}

class Level {
  final String id;
  final int world;
  final GridSize grid;
  final int moveLimit;
  final int? timeLimitSec;
  final List<Block> blocks;
  final List<Gate> gates;
  final List<BlockCell> walls;
  final LevelSolverData? solver;
  final int? seed;
  final String? generatorVersion;

  const Level({
    required this.id,
    required this.world,
    required this.grid,
    required this.moveLimit,
    this.timeLimitSec,
    required this.blocks,
    this.gates = const [],
    this.walls = const [],
    this.solver,
    this.seed,
    this.generatorVersion,
  });

  factory Level.fromJson(Map<String, dynamic> json) {
    return Level(
      id: json['id'] as String,
      world: json['world'] as int,
      grid: GridSize.fromJson(json['grid'] as Map<String, dynamic>),
      moveLimit: json['moveLimit'] as int,
      timeLimitSec: json['timeLimitSec'] as int?,
      blocks: (json['blocks'] as List)
          .map((b) => Block.fromJson(b as Map<String, dynamic>))
          .toList(),
      gates: json['gates'] != null
          ? (json['gates'] as List)
              .map((g) => Gate.fromJson(g as Map<String, dynamic>))
              .toList()
          : [],
      walls: json['walls'] != null
          ? (json['walls'] as List).map((w) => BlockCell.fromJson(w as List)).toList()
          : [],
      solver: json['solver'] != null
          ? LevelSolverData.fromJson(json['solver'] as Map<String, dynamic>)
          : null,
      seed: json['seed'] as int?,
      generatorVersion: json['generatorVersion'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'world': world,
      'grid': grid.toJson(),
      'moveLimit': moveLimit,
      if (timeLimitSec != null) 'timeLimitSec': timeLimitSec,
      'blocks': blocks.map((b) => b.toJson()).toList(),
      if (gates.isNotEmpty) 'gates': gates.map((g) => g.toJson()).toList(),
      if (walls.isNotEmpty) 'walls': walls.map((w) => [w.x, w.y]).toList(),
      if (solver != null) 'solver': solver!.toJson(),
      if (seed != null) 'seed': seed,
      if (generatorVersion != null) 'generatorVersion': generatorVersion,
    };
    return json;
  }

  String toJsonString() => const JsonEncoder.withIndent('  ').convert(toJson());

  int get levelNumber {
    final parts = id.split('-');
    if (parts.length >= 2) {
      return int.tryParse(parts[1]) ?? 0;
    }
    return 0;
  }

  @override
  String toString() => 'Level($id, world: $world, ${grid.width}x${grid.height})';
}
