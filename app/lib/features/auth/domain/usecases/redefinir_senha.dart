/// Valida a recuperação de senha antes de ir à API.
///
/// Passo 1 (pedir o código) usa só [validarEmail]. Passo 2 (código e
/// senha nova) usa [validar]. Os limites são os do contrato: código de
/// 6 dígitos, senha de 8 a 72 caracteres.
class RedefinirSenha {
  const RedefinirSenha();

  static final _seisDigitos = RegExp(r'^[0-9]{6}$');

  String? validarEmail(String email) {
    final limpo = email.trim();
    if (limpo.isEmpty || !limpo.contains('@')) {
      return 'Informe o e-mail da conta.';
    }
    return null;
  }

  String? validar({
    required String email,
    required String codigo,
    required String senhaNova,
  }) {
    final erroEmail = validarEmail(email);
    if (erroEmail != null) return erroEmail;
    if (!_seisDigitos.hasMatch(codigo.trim())) {
      return 'O código tem 6 dígitos.';
    }
    if (senhaNova.length < 8) {
      return 'Senha de no mínimo 8 caracteres.';
    }
    if (senhaNova.length > 72) {
      return 'Senha de no máximo 72 caracteres.';
    }
    return null;
  }
}
