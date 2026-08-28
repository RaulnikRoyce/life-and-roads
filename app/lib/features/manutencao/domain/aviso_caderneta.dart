/// Aviso da caderneta (óleo, papelada, km). Sem feed e sem API.
class AvisoCaderneta {
  const AvisoCaderneta({
    required this.id,
    required this.texto,
    required this.atrasado,
    this.porKm = false,
  });

  final String id;
  final String texto;
  final bool atrasado;
  final bool porKm;
}
