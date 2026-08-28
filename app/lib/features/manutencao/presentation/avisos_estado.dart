import 'package:life_and_roads/features/manutencao/domain/aviso_caderneta.dart';

class AvisosEstado {
  const AvisosEstado({
    this.avisos = const [],
    this.lidos = const {},
    this.permissaoNegada = false,
  });

  final List<AvisoCaderneta> avisos;
  final Set<String> lidos;
  final bool permissaoNegada;

  int get naoLidas =>
      avisos.where((a) => !lidos.contains(a.id)).length;

  AvisosEstado copiarCom({
    List<AvisoCaderneta>? avisos,
    Set<String>? lidos,
    bool? permissaoNegada,
  }) {
    return AvisosEstado(
      avisos: avisos ?? this.avisos,
      lidos: lidos ?? this.lidos,
      permissaoNegada: permissaoNegada ?? this.permissaoNegada,
    );
  }
}
