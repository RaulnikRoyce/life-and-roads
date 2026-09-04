/// Ambiente de build: development | staging | production.
///
/// `flutter run` sem define = development (sem envio de crash).
/// Staging/produção: `--dart-define=ENV=staging` (ou production) e
/// `--dart-define=CRASH_REPORTING=true`.
/// URL da API: `--dart-define=API_BASE=https://...` (senão, localhost:3001).
class Ambiente {
  static const nome = String.fromEnvironment(
    'ENV',
    defaultValue: 'development',
  );

  static const _crashFlag = bool.fromEnvironment(
    'CRASH_REPORTING',
    defaultValue: false,
  );

  static const _apiBase = String.fromEnvironment('API_BASE');

  static bool get producao => nome == 'production';
  static bool get staging => nome == 'staging';

  /// Campo Servidor (LAN) só no desenvolvimento. Loja e staging usam `API_BASE`.
  static bool get exibeCampoServidor =>
      exibeCampoServidorDe(producao: producao, staging: staging);

  static bool exibeCampoServidorDe({
    required bool producao,
    required bool staging,
  }) =>
      !producao && !staging;

  /// Relato de crash só fora do desenvolvimento, ou se o define estiver ligado.
  static bool get relataCrash =>
      _crashFlag || staging || producao;

  /// Origem da URL: dart-define, depois o fallback de desenvolvimento.
  /// IMPORTANTE: URLs remotas devem usar HTTPS. HTTP só é permitido para localhost.
  static String get apiPadrao {
    final t = _apiBase.trim();
    if (t.isEmpty) return 'http://localhost:3001';
    return t.endsWith('/') ? t.substring(0, t.length - 1) : t;
  }
}
