class Sessao {
  const Sessao({
    this.token,
    this.email,
    required this.servidor,
    this.termosVersao,
  });

  final String? token;
  final String? email;
  final String servidor;

  /// Versão dos termos que a conta aceitou, como veio do login ou da
  /// redefinição de senha. Não é guardada aqui: quem guarda é a nuvem.
  final String? termosVersao;

  bool get logado => token != null && token!.isNotEmpty;

  Sessao copiarCom({
    String? token,
    String? email,
    String? servidor,
    bool limpar = false,
  }) {
    return Sessao(
      token: limpar ? null : (token ?? this.token),
      email: limpar ? null : (email ?? this.email),
      servidor: servidor ?? this.servidor,
    );
  }
}
