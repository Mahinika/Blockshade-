import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

class GameProvider extends ChangeNotifier {
  final LevelService _levelService;
  final StorageService _storageService;
  final AnalyticsService _analyticsService;
  final RemoteConfigService _remoteConfig;
  final DailyPuzzleService _dailyPuzzleService;

  GameState? _gameState;
  Level? _currentLevel;
  PlayerProgress _progress = PlayerProgress.initial();
  int _attemptNo = 1;
  int _continuesUsed = 0;
  DateTime? _levelStartTime;
  List<String> _boostersUsed = [];
  bool _isLoading = false;

  GameProvider({
    required LevelService levelService,
    required StorageService storageService,
    required AnalyticsService analyticsService,
    required RemoteConfigService remoteConfig,
    required DailyPuzzleService dailyPuzzleService,
  })  : _levelService = levelService,
        _storageService = storageService,
        _analyticsService = analyticsService,
        _remoteConfig = remoteConfig,
        _dailyPuzzleService = dailyPuzzleService;

  GameState? get gameState => _gameState;
  Level? get currentLevel => _currentLevel;
  PlayerProgress get progress => _progress;
  bool get isLoading => _isLoading;

  bool get isWon => _gameState?.isWon ?? false;
  bool get isLost => _gameState?.isLost ?? false;
  bool get isGameOver => _gameState?.isGameOver ?? false;
  int get movesRemaining => _gameState?.movesRemaining ?? 0;
  int get movesUsed => _gameState?.movesUsed ?? 0;
  int get stars => _gameState?.stars ?? 0;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    _progress = await _storageService.loadProgress();
    await _analyticsService.setAdsRemoved(_progress.adsRemoved);
    await _analyticsService.setPayerStatus(_progress.payerStatus);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> applyIapGrant(IapGrant grant) async {
    var progress = _progress;
    if (grant.productId == IapProducts.starterPack && grant.firstUnlock) {
      progress = progress.purchaseStarterPack(hints: grant.hints);
    } else if (grant.removesAds) {
      progress = progress.removeAds();
      if (grant.productId == IapProducts.starterPack) {
        progress = progress.copyWith(starterPackPurchased: true);
      }
    }
    if (grant.hints > 0 && grant.productId != IapProducts.starterPack) {
      progress = progress.addHints(grant.hints);
    }
    if (grant.coins > 0) {
      progress = progress.addCoins(grant.coins);
      _analyticsService.logCurrencyEarn(
        amount: grant.coins,
        source: 'iap',
        balanceAfter: progress.coins,
      );
    }
    if (grant.extraMoveCredits > 0) {
      progress = progress.addExtraMoveCredits(grant.extraMoveCredits);
    }
    if (grant.countsAsPurchase) {
      progress = progress.copyWith(iapPurchaseCount: progress.iapPurchaseCount + 1);
    }
    _progress = progress;
    await _storageService.saveProgress(_progress);
    await _analyticsService.setAdsRemoved(_progress.adsRemoved);
    await _analyticsService.setPayerStatus(_progress.payerStatus);
    notifyListeners();
  }

  bool spendHint() {
    if (_progress.hintsOwned <= 0) return false;
    _progress = _progress.spendHint();
    _storageService.saveProgress(_progress);
    notifyListeners();
    return true;
  }

  bool spendExtraMoveCredit() {
    if (_progress.extraMoveCredits <= 0 || _gameState == null) return false;
    _progress = _progress.spendExtraMoveCredit();
    _storageService.saveProgress(_progress);
    addExtraMoves(5);
    return true;
  }

  Future<void> loadLevel(String levelId) async {
    _isLoading = true;
    notifyListeners();

    if (DailyPuzzleService.isDailyLevelId(levelId)) {
      final date = DailyPuzzleService.dateFromLevelId(levelId) ?? DateTime.now();
      _currentLevel = await _dailyPuzzleService.getLevelForDate(date);
    } else {
      _currentLevel = await _levelService.loadLevel(levelId);
    }
    if (_currentLevel != null) {
      _gameState = GameState.fromLevel(_currentLevel!);
      _attemptNo = 1;
      _continuesUsed = 0;
      _levelStartTime = DateTime.now();
      _boostersUsed = [];

      _analyticsService.logLevelStart(
        levelId: levelId,
        world: _currentLevel!.world,
        attemptNo: _attemptNo,
        moveLimit: _currentLevel!.moveLimit,
        timeLimit: _currentLevel!.timeLimitSec,
        difficulty: _currentLevel!.solver?.difficulty ?? 0.5,
        livesLeft: _progress.currentLives,
      );
    }

    _isLoading = false;
    notifyListeners();
  }

  void makeMove(String blockId) {
    if (_gameState == null || _gameState!.isGameOver) return;

    final outcome = _gameState!.tryMoveBlock(blockId);
    if (outcome == null || outcome.result == MoveResult.blocked) return;

    _gameState = _gameState!.applyMove(blockId);
    notifyListeners();

    if (_gameState!.isWon) {
      _onLevelComplete();
    } else if (_gameState!.isLost) {
      _onLevelFail();
    }
  }

  void _onLevelComplete() {
    if (_currentLevel == null || _gameState == null) return;

    final levelId = _currentLevel!.id;
    final world = _currentLevel!.world;
    final earnedStars = _gameState!.stars;
    final durationSec = DateTime.now().difference(_levelStartTime!).inSeconds;

    final coinsEarned = _remoteConfig.coinsBaseWin + (earnedStars * _remoteConfig.coinsPerStar);
    if (DailyPuzzleService.isDailyLevelId(levelId)) {
      final date = DailyPuzzleService.dateFromLevelId(levelId) ?? DateTime.now();
      _progress = _progress
          .recordDailyCompletion(date, earnedStars)
          .addCoins(coinsEarned);
    } else {
      _progress = _progress
          .updateLevelProgress(levelId, earnedStars, _gameState!.movesUsed)
          .addCoins(coinsEarned);
    }

    _storageService.saveProgress(_progress);

    _analyticsService.logLevelComplete(
      levelId: levelId,
      world: world,
      attemptNo: _attemptNo,
      movesUsed: _gameState!.movesUsed,
      movesLeft: _gameState!.movesRemaining,
      stars: earnedStars,
      durationSec: durationSec,
      boostersUsed: _boostersUsed,
      continuesUsed: _continuesUsed,
    );

    _analyticsService.logCurrencyEarn(
      amount: coinsEarned,
      source: 'level_complete',
      balanceAfter: _progress.coins,
    );

    notifyListeners();
  }

  void _onLevelFail() {
    if (_currentLevel == null || _gameState == null) return;

    final durationSec = DateTime.now().difference(_levelStartTime!).inSeconds;

    _analyticsService.logLevelFail(
      levelId: _currentLevel!.id,
      world: _currentLevel!.world,
      attemptNo: _attemptNo,
      reason: 'moves',
      blocksLeft: _gameState!.blocks.length,
      movesUsed: _gameState!.movesUsed,
      durationSec: durationSec,
      optimalMoves: _currentLevel!.solver?.optimalMoves ?? 0,
    );

    notifyListeners();
  }

  bool canUndo() => _gameState?.canUndo() ?? false;

  void undo() {
    if (_gameState == null || !canUndo()) return;

    if (_progress.undoBoostersOwned <= 0) return;

    final prevState = _gameState!.undo();
    if (prevState != null) {
      _gameState = prevState;
      _progress = _progress.useUndoBooster();
      _boostersUsed.add('undo');

      _analyticsService.logBoosterUsed(
        levelId: _currentLevel?.id ?? '',
        world: _currentLevel?.world ?? 0,
        booster: 'undo',
        source: 'owned',
        moment: 'in_level',
      );

      _storageService.saveProgress(_progress);
      notifyListeners();
    }
  }

  void addExtraMoves(int moves) {
    if (_gameState == null) return;

    _gameState = _gameState!.addMoves(moves);
    _continuesUsed++;
    notifyListeners();
  }

  bool canBuyContinueWithCoins(int failCount) {
    final cost = failCount <= 1
        ? _remoteConfig.extraMovesCoinCost
        : _remoteConfig.extraMovesCoinCostSecond;
    return _progress.coins >= cost;
  }

  void buyContinueWithCoins(int failCount) {
    final cost = failCount <= 1
        ? _remoteConfig.extraMovesCoinCost
        : _remoteConfig.extraMovesCoinCostSecond;

    if (_progress.coins < cost) return;

    _progress = _progress.spendCoins(cost);
    _analyticsService.logCurrencySpend(
      amount: cost,
      sink: 'continue_5_moves',
      balanceAfter: _progress.coins,
    );

    addExtraMoves(5);
    _storageService.saveProgress(_progress);
  }

  void restartLevel() {
    if (_currentLevel == null) return;

    _progress = _progress.useLife();
    _storageService.saveProgress(_progress);

    _gameState = GameState.fromLevel(_currentLevel!);
    _attemptNo++;
    _levelStartTime = DateTime.now();
    _boostersUsed = [];

    _analyticsService.logLevelStart(
      levelId: _currentLevel!.id,
      world: _currentLevel!.world,
      attemptNo: _attemptNo,
      moveLimit: _currentLevel!.moveLimit,
      timeLimit: _currentLevel!.timeLimitSec,
      difficulty: _currentLevel!.solver?.difficulty ?? 0.5,
      livesLeft: _progress.currentLives,
    );

    notifyListeners();
  }

  void quitLevel() {
    if (_currentLevel == null || _levelStartTime == null) return;

    final durationSec = DateTime.now().difference(_levelStartTime!).inSeconds;
    _analyticsService.logLevelQuit(
      levelId: _currentLevel!.id,
      world: _currentLevel!.world,
      movesUsed: _gameState?.movesUsed ?? 0,
      durationSec: durationSec,
    );

    _gameState = null;
    _currentLevel = null;
    notifyListeners();
  }

  Future<void> goToNextLevel() async {
    if (_currentLevel == null) return;

    final nextLevel = await _levelService.getNextLevel(_currentLevel!.id);
    if (nextLevel != null) {
      await loadLevel(nextLevel.id);
    }
  }

  void addCoins(int amount, String source) {
    _progress = _progress.addCoins(amount);
    _analyticsService.logCurrencyEarn(
      amount: amount,
      source: source,
      balanceAfter: _progress.coins,
    );
    _storageService.saveProgress(_progress);
    notifyListeners();
  }

  void purchaseStarterPack() {
    _progress = _progress.purchaseStarterPack();
    _storageService.saveProgress(_progress);
    notifyListeners();
  }

  void removeAds() {
    _progress = _progress.removeAds();
    _storageService.saveProgress(_progress);
    notifyListeners();
  }

  void addUndoBoosters(int amount) {
    _progress = _progress.addUndoBoosters(amount);
    _storageService.saveProgress(_progress);
    notifyListeners();
  }

  void addLives(int amount) {
    _progress = _progress.addLives(amount);
    _storageService.saveProgress(_progress);
    notifyListeners();
  }
}
