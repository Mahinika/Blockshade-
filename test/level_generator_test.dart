import 'package:flutter_test/flutter_test.dart';
import 'package:blockshade/services/level_generator.dart';
import 'package:blockshade/services/solver.dart';

void main() {
  group('LevelGenerator', () {
    test('generates solvable level for world 1', () {
      final generator = LevelGenerator(seed: 12345);
      final config = GeneratorConfig.forWorld(1, levelInWorld: 5, isBoss: false);
      
      final level = generator.generate('test-w1-005', config);

      expect(level, isNotNull);
      expect(level!.solver?.solvable, true);
      expect(level.blocks.isNotEmpty, true);
      expect(level.moveLimit, greaterThan(0));
    });

    test('config has echo chance after level 8 in world 1', () {
      final config = GeneratorConfig.forWorld(1, levelInWorld: 10, isBoss: false);
      expect(config.echoBlockChance, greaterThan(0));
    });

    test('config has lock chance in world 2', () {
      final config = GeneratorConfig.forWorld(2, levelInWorld: 10, isBoss: false);
      expect(config.lockedBlockChance, greaterThan(0));
    });

    test('config has gate chance in world 3', () {
      final config = GeneratorConfig.forWorld(3, levelInWorld: 10, isBoss: false);
      expect(config.gateChance, greaterThan(0));
    });

    test('boss levels have lower slack', () {
      final normalConfig = GeneratorConfig.forWorld(1, levelInWorld: 15, isBoss: false);
      final bossConfig = GeneratorConfig.forWorld(1, levelInWorld: 20, isBoss: true);

      expect(bossConfig.slack, lessThan(normalConfig.slack));
      expect(bossConfig.slack, equals(1));
    });

    test('difficulty increases with level number', () {
      final earlyConfig = GeneratorConfig.forWorld(1, levelInWorld: 3, isBoss: false);
      final lateConfig = GeneratorConfig.forWorld(1, levelInWorld: 18, isBoss: false);

      expect(lateConfig.maxBlocks, greaterThanOrEqualTo(earlyConfig.maxBlocks));
    });

    test('verifies generated level with solver', () {
      final generator = LevelGenerator(seed: 11111);
      final config = GeneratorConfig.forWorld(1, levelInWorld: 5, isBoss: false);
      
      final level = generator.generate('verify-test', config);
      
      if (level != null) {
        final solver = Solver(level);
        final result = solver.solve();
        
        expect(result.solvable, true);
        expect(result.optimalMoves, level.solver?.optimalMoves);
      }
    });
  });

  group('LevelBatchGenerator', () {
    test('generates 20 levels for a world', () {
      final batchGenerator = LevelBatchGenerator(seed: 99999);
      final levels = batchGenerator.generateWorld(1, 20);

      expect(levels.length, 20);
      
      for (var i = 0; i < levels.length; i++) {
        final level = levels[i];
        expect(level.world, 1);
        expect(level.solver?.solvable, true);
      }
    });

    test('level IDs are sequential', () {
      final batchGenerator = LevelBatchGenerator(seed: 88888);
      final levels = batchGenerator.generateWorld(2, 5);

      expect(levels[0].id, 'w2-001');
      expect(levels[1].id, 'w2-002');
      expect(levels[2].id, 'w2-003');
      expect(levels[3].id, 'w2-004');
      expect(levels[4].id, 'w2-005');
    });
  });

  group('GeneratorConfig', () {
    test('world 1 config has no locks or gates', () {
      final config = GeneratorConfig.forWorld(1, levelInWorld: 10, isBoss: false);

      expect(config.lockedBlockChance, 0);
      expect(config.gateChance, 0);
    });

    test('world 2 config has locks but no gates', () {
      final config = GeneratorConfig.forWorld(2, levelInWorld: 10, isBoss: false);

      expect(config.lockedBlockChance, greaterThan(0));
      expect(config.gateChance, 0);
    });

    test('world 3 config has gates', () {
      final config = GeneratorConfig.forWorld(3, levelInWorld: 10, isBoss: false);

      expect(config.gateChance, greaterThan(0));
    });

    test('echo blocks start from level 8 in world 1', () {
      final beforeEcho = GeneratorConfig.forWorld(1, levelInWorld: 7, isBoss: false);
      final afterEcho = GeneratorConfig.forWorld(1, levelInWorld: 8, isBoss: false);

      expect(beforeEcho.echoBlockChance, 0);
      expect(afterEcho.echoBlockChance, greaterThan(0));
    });
  });
}
