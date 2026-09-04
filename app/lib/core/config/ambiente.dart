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
  }) => !producao && !staging;

  /// Relato de crash só fora do desenvolvimento, ou se o define estiver ligado.
  static bool get relataCrash => _crashFlag || staging || producao;

  /// Origem da URL: dart-define, depois o fallback de desenvolvimento.
  static String get apiPadrao {
    final t = _apiBase.trim();
    if (t.isEmpty) return 'http://localhost:3001';
    return validarApiBase(t, producao: producao, staging: staging);
  }

  static String validarApiBase(
    String valor, {
    required bool producao,
    required bool staging,
  }) {
    final t = valor.trim();
    final url = t.endsWith('/') ? t.substring(0, t.length - 1) : t;
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw StateError('API_BASE inválida.');
    }
    if ((producao || staging) && uri.scheme != 'https') {
      throw StateError('API_BASE deve usar HTTPS em staging e produção.');
    }
    return url;
  }
}
