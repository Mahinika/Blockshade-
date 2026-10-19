import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blockshade/services/preferences_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PreferencesStore.instance.resetForTesting();
  });

  test('reads and writes via mock shared preferences', () async {
    final store = PreferencesStore.instance;
    await store.ensureReady();
    expect(store.isMemoryOnly, isFalse);

    await store.setString('k', 'v');
    expect(await store.getString('k'), 'v');
  });
}
