/// Textos de GPS e câmera recusados (web e aparelho).
class MensagensPermissao {
  static String gpsDesligado({required bool web}) {
    return web
        ? 'Ligue a localização do aparelho (ou permita no Chrome).'
        : 'Ligue o GPS deste celular.';
  }

  static String gpsNegada({required bool web}) {
    return web
        ? 'Sem permissão de localização. No Chrome, aceite o pedido do site.'
        : 'Sem permissão de localização. Autorize o GPS para o app.';
  }

  static const camera =
      'Não deu para abrir a câmera. Tente a galeria.';

  static const notificacao =
      'Sem permissão de aviso. Autorize as notificações para lembrar óleo e papelada.';
}
