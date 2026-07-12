import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Serviço central de anúncios AdMob.
/// - Banner: artigos, home, marketplace, fornecedores
/// - Rewarded: ganhar créditos de IA
/// - App Open: abertura/retorno à app
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  // true = IDs de teste (sempre aparecem, útil para debug)
  // false = IDs reais (só aparecem em release com conta AdMob ativa)
  static const bool _useTestIds = true;

  // ── IDs reais ──────────────────────────────────────────────────
  static const String _realBannerAndroid   = 'ca-app-pub-1226934178942790/2310041516';
  static const String _realRewardedAndroid = 'ca-app-pub-1226934178942790/7326143019';
  static const String _realAppOpenAndroid  = 'ca-app-pub-1226934178942790/1220321120';

  // ── IDs de teste ───────────────────────────────────────────────
  static const String _testBanner   = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testRewarded = 'ca-app-pub-3940256099942544/5224354917';
  static const String _testAppOpen  = 'ca-app-pub-3940256099942544/9257395921';

  String get bannerUnitId   => _useTestIds ? _testBanner   : _realBannerAndroid;
  String get rewardedUnitId => _useTestIds ? _testRewarded : _realRewardedAndroid;
  String get appOpenUnitId  => _useTestIds ? _testAppOpen  : _realAppOpenAndroid;

  // ── Estado ─────────────────────────────────────────────────────
  RewardedAd?   _rewardedAd;
  AppOpenAd?    _appOpenAd;
  bool          _isLoadingRewarded = false;
  bool          _isLoadingAppOpen  = false;
  bool          _appOpenShowing    = false;
  DateTime?     _appOpenLoadTime;

  // ── Init ───────────────────────────────────────────────────────
  Future<void> init() async {
    await MobileAds.instance.initialize();
    preloadRewarded();
    preloadAppOpen();
    if (kDebugMode) debugPrint('[ads] AdMob inicializado.');
  }

  // ════════════════ REWARDED ════════════════════════════════════

  void preloadRewarded() {
    if (_rewardedAd != null || _isLoadingRewarded) return;
    _isLoadingRewarded = true;
    RewardedAd.load(
      adUnitId: rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoadingRewarded = false;
          if (kDebugMode) debugPrint('[ads] Rewarded carregado.');
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isLoadingRewarded = false;
          if (kDebugMode) debugPrint('[ads] Rewarded falhou: $error');
          Future.delayed(const Duration(seconds: 30), preloadRewarded);
        },
      ),
    );
  }

  bool get isRewardedReady => _rewardedAd != null;

  Future<bool> showRewarded({required VoidCallback onReward}) async {
    if (_rewardedAd == null) { preloadRewarded(); return false; }
    final completer = Completer<bool>();
    bool rewarded = false;
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose(); _rewardedAd = null; preloadRewarded();
        if (!completer.isCompleted) completer.complete(rewarded);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose(); _rewardedAd = null; preloadRewarded();
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    await _rewardedAd!.show(onUserEarnedReward: (_, __) {
      rewarded = true; onReward();
    });
    return completer.future;
  }

  // ════════════════ APP OPEN ════════════════════════════════════

  void preloadAppOpen() {
    if (_appOpenAd != null || _isLoadingAppOpen) return;
    _isLoadingAppOpen = true;
    AppOpenAd.load(
      adUnitId: appOpenUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _appOpenLoadTime = DateTime.now();
          _isLoadingAppOpen = false;
          if (kDebugMode) debugPrint('[ads] AppOpen carregado.');
        },
        onAdFailedToLoad: (error) {
          _appOpenAd = null;
          _isLoadingAppOpen = false;
          if (kDebugMode) debugPrint('[ads] AppOpen falhou: $error');
        },
      ),
    );
  }

  /// App Open Ad expira após 4 horas — verificação obrigatória.
  bool get _isAppOpenAdValid {
    if (_appOpenAd == null) return false;
    if (_appOpenLoadTime == null) return false;
    return DateTime.now().difference(_appOpenLoadTime!) < const Duration(hours: 4);
  }

  /// Mostra o App Open Ad se disponível e válido.
  /// Chamar em [SplashScreen] após o carregamento inicial.
  Future<void> showAppOpenAd() async {
    if (_appOpenShowing || !_isAppOpenAdValid) {
      preloadAppOpen();
      return;
    }
    _appOpenShowing = true;
    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        _appOpenShowing = false;
        ad.dispose();
        _appOpenAd = null;
        preloadAppOpen();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _appOpenShowing = false;
        ad.dispose();
        _appOpenAd = null;
        preloadAppOpen();
      },
    );
    await _appOpenAd!.show();
  }
}
