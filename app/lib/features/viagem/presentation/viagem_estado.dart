import 'package:life_and_roads/features/ficha/domain/ficha_moto.dart';
import 'package:life_and_roads/features/viagem/domain/precos_litro.dart';
import 'package:life_and_roads/viagem/calculo.dart';

class ViagemEstado {
  const ViagemEstado({
    this.carregando = true,
    this.ficha,
    this.precos = const PrecosLitro(),
    this.historico = const [],
    this.resultado,
    this.combustivelViagem = Combustivel.gasolina,
    this.combustivelAbastecimento = Combustivel.gasolina,
    this.aviso,
    this.erro,
    this.offline = false,
  });

  final bool carregando;
  final FichaMoto? ficha;
  final PrecosLitro precos;
  final List<RegistroAbastecimento> historico;
  final ResultadoViagem? resultado;
  final Combustivel combustivelViagem;
  final Combustivel combustivelAbastecimento;
  final String? aviso;
  final String? erro;
  final bool offline;

  double? get kmLitroGasolina => ficha?.kmLitro;
  double? get kmLitroAlcool => ficha?.kmLitroAlcool;
  double? get kmAtual => ficha?.kmAtual;
  double? get tanqueLitros => ficha?.tanqueLitros;

  double? get kmLitroViagem => combustivelViagem == Combustivel.alcool
      ? kmLitroAlcool
      : kmLitroGasolina;

  ViagemEstado copiarCom({
    bool? carregando,
    FichaMoto? ficha,
    bool limparFicha = false,
    PrecosLitro? precos,
    List<RegistroAbastecimento>? historico,
    ResultadoViagem? resultado,
    bool limparResultado = false,
    Combustivel? combustivelViagem,
    Combustivel? combustivelAbastecimento,
    String? aviso,
    bool limparAviso = false,
    String? erro,
    bool limparErro = false,
    bool? offline,
  }) {
    return ViagemEstado(
      carregando: carregando ?? this.carregando,
      ficha: limparFicha ? null : (ficha ?? this.ficha),
      precos: precos ?? this.precos,
      historico: historico ?? this.historico,
      resultado: limparResultado ? null : (resultado ?? this.resultado),
      combustivelViagem: combustivelViagem ?? this.combustivelViagem,
      combustivelAbastecimento:
          combustivelAbastecimento ?? this.combustivelAbastecimento,
      aviso: limparAviso ? null : (aviso ?? this.aviso),
      erro: limparErro ? null : (erro ?? this.erro),
      offline: offline ?? this.offline,
    );
  }
}
