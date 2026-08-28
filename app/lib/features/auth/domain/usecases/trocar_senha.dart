/// Valida a troca de senha antes de ir à API.
class TrocarSenha {
  const TrocarSenha();

  String? validar({
    required String senhaAtual,
    required String senhaNova,
  }) {
    if (senhaAtual.length < 8 || senhaNova.length < 8) {
      return 'Senha de no mínimo 8 caracteres.';
    }
    if (senhaNova == senhaAtual) {
      return 'A senha nova tem que ser diferente da atual.';
    }
    return null;
  }
}
