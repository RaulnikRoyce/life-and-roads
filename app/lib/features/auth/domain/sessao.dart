class Sessao {
  const Sessao({
    this.token,
    this.email,
    required this.servidor,
  });

  final String? token;
  final String? email;
  final String servidor;

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
