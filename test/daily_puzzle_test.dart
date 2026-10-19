import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blockshade/services/daily_puzzle_service.dart';
import 'package:blockshade/services/solver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DailyPuzzleService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('seed is deterministic from calendar date', () {
      final a = DailyPuzzleService.seedForDate(DateTime(2026, 10, 19));
      final b = DailyPuzzleService.seedForDate(DateTime(2026, 10, 19));
      final c = DailyPuzzleService.seedForDate(DateTime(2026, 10, 20));

      expect(a, b);
      expect(a, 20261019);
      expect(c, isNot(equals(a)));
    });

    test('level id encodes date', () {
      final id = DailyPuzzleService.levelIdForDate(DateTime(2026, 3, 5));
      expect(id, 'daily-2026-03-05');
      expect(
        DailyPuzzleService.dateFromLevelId(id),
        DateTime(2026, 3, 5),
      );
    });

    test('generated daily level is stable for the same date', () async {
      final service = DailyPuzzleService();
      final date = DateTime(2026, 7, 4);

      final first = await service.getLevelForDate(date);
      final second = await service.getLevelForDate(date);

      expect(first.id, second.id);
      expect(first.moveLimit, second.moveLimit);
      expect(first.blocks.length, second.blocks.length);

      final solver = Solver(first);
      expect(solver.solve().solvable, isTrue);
    });

    test('different dates produce different puzzles', () async {
      final service = DailyPuzzleService();
      final a = await service.getLevelForDate(DateTime(2026, 1, 1));
      final b = await service.getLevelForDate(DateTime(2026, 1, 2));

      expect(a.id, isNot(equals(b.id)));
    });

    test('generation terminates within bounded time for 365 consecutive dates', () async {
      final service = DailyPuzzleService();
      const maxPerDateMs = 4000;
      const maxTotalMs = 180000;

      final total = Stopwatch()..start();
      for (var day = 0; day < 365; day++) {
        final date = DateTime(2026, 1, 1).add(Duration(days: day));
        final perDate = Stopwatch()..start();
        final level = await service.generateForDateWithoutCache(date);
        perDate.stop();
        expect(perDate.elapsedMilliseconds, lessThan(maxPerDateMs));
        expect(level.id, DailyPuzzleService.levelIdForDate(date));
        expect(level.blocks.isNotEmpty, isTrue);
      }
      total.stop();
      expect(total.elapsedMilliseconds, lessThan(maxTotalMs));
    });
  });
}
