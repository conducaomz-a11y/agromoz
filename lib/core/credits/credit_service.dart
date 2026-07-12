import 'package:flutter/foundation.dart';
import '../network/api_client.dart';

/// Serviço de créditos de IA — persistidos NO SERVIDOR (tabela app_credits).
///
/// Ao contrário da versão anterior (SharedPreferences), os créditos ficam
/// ligados à conta do utilizador. Limpar dados do app, reinstalar ou trocar
/// de telemóvel não perde nem repõe créditos indevidamente.
///
/// Cache local em memória evita chamadas repetidas à API na mesma sessão.
class CreditService {
  CreditService._();
  static final CreditService instance = CreditService._();

  static const int creditsPerAd      = 1;
  static const int costPerGeneration = 1;

  final _client = ApiClient.instance;

  // Cache em memória (válida durante a sessão).
  int? _cachedBalance;

  // ── Saldo ─────────────────────────────────────────────────────

  /// Retorna o saldo atual. Usa cache se disponível; caso contrário chama API.
  Future<int> fetchBalance() async {
    if (_cachedBalance != null) return _cachedBalance!;
    try {
      final data = await _client.get<Map<String, dynamic>>('/credits/balance');
      _cachedBalance = (data['data']?['balance'] as num?)?.toInt() ?? 0;
    } catch (e) {
      if (kDebugMode) debugPrint('[credits] fetchBalance erro: $e');
      _cachedBalance = 0;
    }
    return _cachedBalance!;
  }

  /// Saldo em cache (0 se ainda não carregado).
  int get balance => _cachedBalance ?? 0;

  bool get canGenerate => balance >= costPerGeneration;

  /// Invalida cache — chama após login/logout.
  void invalidate() => _cachedBalance = null;

  // ── Ganhar crédito (após anúncio) ─────────────────────────────

  /// Adiciona 1 crédito no servidor após o utilizador ver um anúncio completo.
  Future<int> addCreditsFromAd() async {
    try {
      final data = await _client.post<Map<String, dynamic>>(
        '/credits/add',
        data: {'amount': creditsPerAd, 'source': 'ad'},
      );
      _cachedBalance = (data['data']?['balance'] as num?)?.toInt() ?? balance + creditsPerAd;
    } catch (e) {
      if (kDebugMode) debugPrint('[credits] addCreditsFromAd erro: $e');
      // Fallback otimista: incrementa cache local para não bloquear UX.
      _cachedBalance = balance + creditsPerAd;
    }
    return _cachedBalance!;
  }

  // ── Gastar crédito (gerar descrição) ──────────────────────────

  /// Debita 1 crédito no servidor.
  /// Devolve true se bem sucedido, false se saldo insuficiente ou erro.
  Future<bool> spend() async {
    if (!canGenerate) return false;
    try {
      final data = await _client.post<Map<String, dynamic>>(
        '/credits/spend',
        data: {'amount': costPerGeneration},
      );
      _cachedBalance = (data['data']?['balance'] as num?)?.toInt() ?? balance - costPerGeneration;
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[credits] spend erro: $e');
      return false;
    }
  }

  /// Reembolsa 1 crédito quando a geração falha no servidor.
  Future<void> refund() async {
    try {
      final data = await _client.post<Map<String, dynamic>>(
        '/credits/add',
        data: {'amount': costPerGeneration, 'source': 'refund'},
      );
      _cachedBalance = (data['data']?['balance'] as num?)?.toInt() ?? balance + costPerGeneration;
    } catch (e) {
      _cachedBalance = balance + costPerGeneration;
    }
  }
}
