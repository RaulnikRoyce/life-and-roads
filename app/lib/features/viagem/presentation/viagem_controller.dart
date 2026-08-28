import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_and_roads/features/ficha/data/ficha_local_datasource.dart';
import 'package:life_and_roads/features/ficha/domain/ficha_repository.dart';
import 'package:life_and_roads/features/ficha/presentation/ficha_controller.dart';
import 'package:life_and_roads/features/viagem/data/abastecimento_local_datasource.dart';
import 'package:life_and_roads/features/viagem/data/precos_local_datasource.dart';
import 'package:life_and_roads/features/viagem/data/viagem_repository_impl.dart';
import 'package:life_and_roads/features/viagem/domain/precos_litro.dart';
import 'package:life_and_roads/features/viagem/domain/usecases/calcular_custo_viagem.dart';
import 'package:life_and_roads/features/viagem/domain/usecases/montar_abastecimento.dart';
import 'package:life_and_roads/features/viagem/domain/viagem_repository.dart';
import 'package:life_and_roads/features/viagem/presentation/viagem_estado.dart';
import 'package:life_and_roads/viagem/calculo.dart';

final precosLocalDatasourceProvider = Provider<PrecosLocalDatasource>(
  (_) => PrecosLocalDatasource(),
);

final abastecimentoLocalDatasourceProvider =
    Provider<AbastecimentoLocalDatasource>(
  (_) => AbastecimentoLocalDatasource(),
);

final viagemRepositoryProvider = Provider<ViagemRepository>(
  (ref) => ViagemRepositoryImpl(
    precos: ref.watch(precosLocalDatasourceProvider),
    abastecimentos: ref.watch(abastecimentoLocalDatasourceProvider),
  ),
);

final calcularCustoViagemProvider = Provider<CalcularCustoViagem>(
  (_) => CalcularCustoViagem(),
);

final montarAbastecimentoProvider = Provider<MontarAbastecimento>(
  (_) => MontarAbastecimento(),
);

class ViagemController extends Notifier<ViagemEstado> {
  ViagemRepository get _viagem => ref.read(viagemRepositoryProvider);
  FichaLocalDatasource get _fichaLocal =>
      ref.read(fichaLocalDatasourceProvider);
  FichaRepository get _fichaRepo => ref.read(fichaRepositoryProvider);
  CalcularCustoViagem get _calcular => ref.read(calcularCustoViagemProvider);
  MontarAbastecimento get _montar => ref.read(montarAbastecimentoProvider);

  @override
  ViagemEstado build() => const ViagemEstado();

  Future<void> carregar() async {
    state = state.copiarCom(
      carregando: true,
      limparErro: true,
      limparAviso: true,
    );
    final ficha = await _fichaLocal.ler(recarregar: true);
    final precos = await _viagem.lerPrecos();
    final historico = await _viagem.listarAbastecimentos();
    final comb = ficha?.combustivel ?? Combustivel.gasolina;
    state = ViagemEstado(
      carregando: false,
      ficha: ficha,
      precos: precos,
      historico: historico,
      combustivelViagem: comb,
      combustivelAbastecimento: comb,
    );
  }

  Future<void> relerFicha() async {
    final ficha = await _fichaLocal.ler(recarregar: true);
    state = state.copiarCom(
      ficha: ficha,
      limparFicha: ficha == null,
    );
  }

  void definirCombustivel(Combustivel c) {
    state = state.copiarCom(
      combustivelViagem: c,
      combustivelAbastecimento: c,
      limparResultado: true,
    );
  }

  void definirCombustivelAbastecimento(Combustivel c) {
    state = state.copiarCom(combustivelAbastecimento: c);
  }

  void limparResultado() {
    state = state.copiarCom(limparResultado: true);
  }

  Future<void> calcular({
    required double? km,
    required PrecosLitro precos,
  }) async {
    await relerFicha();
    final kmL = state.combustivelViagem == Combustivel.alcool
        ? state.kmLitroAlcool
        : state.kmLitroGasolina;
    final preco = state.combustivelViagem == Combustivel.alcool
        ? _numero(precos.alcool)
        : _numero(precos.gasolina);
    final r = _calcular.executar(
      km: km,
      kmPorLitro: kmL,
      preco: preco,
      combustivel: state.combustivelViagem,
    );
    if (r.erro != null) {
      state = state.copiarCom(erro: r.erro, limparAviso: true);
      return;
    }
    await _viagem.gravarPrecos(precos);
    state = state.copiarCom(
      resultado: r.resultado,
      precos: precos,
      limparErro: true,
    );
  }

  Future<void> registrarAbastecimento({
    required double? kmPainel,
    required double? litros,
    required PrecosLitro precos,
  }) async {
    await relerFicha();
    final preco = state.combustivelAbastecimento == Combustivel.alcool
        ? _numero(precos.alcool)
        : _numero(precos.gasolina);
    final montado = _montar.executar(
      ficha: state.ficha,
      kmPainel: kmPainel,
      litros: litros,
      preco: preco,
      combustivel: state.combustivelAbastecimento,
    );
    if (montado.erro != null) {
      state = state.copiarCom(erro: montado.erro, limparAviso: true);
      return;
    }

    final salva = await _fichaRepo.salvar(montado.ficha!);
    await _viagem.gravarPrecos(precos);
    final historico =
        await _viagem.acrescentarAbastecimento(montado.registro!);
    state = state.copiarCom(
      ficha: salva.ficha,
      precos: precos,
      historico: historico,
      combustivelViagem: state.combustivelAbastecimento,
      aviso: montado.aviso,
      offline: salva.offline,
      limparErro: true,
    );
  }

  double? _numero(String bruto) {
    final t = bruto.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }
}

final viagemControllerProvider =
    NotifierProvider<ViagemController, ViagemEstado>(ViagemController.new);
