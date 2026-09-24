/// Preços do litro neste aparelho. Sobem só dentro da caderneta na nuvem
/// (ADR 0038).
class PrecosLitro {
  const PrecosLitro({this.gasolina = '', this.alcool = ''});

  final String gasolina;
  final String alcool;
}
