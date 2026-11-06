import 'package:life_and_roads/viagem/calculo.dart';

enum TipoOrigemConsumo {
  referencia,
  estimado,
  medido,
  mistura,
  legado,
  indisponivel,
}

class OrigemConsumo {
  const OrigemConsumo(this.tipo, this.titulo, this.explicacao);
  final TipoOrigemConsumo tipo;
  final String titulo, explicacao;
}

/// Descreve a evidência disponível sem atribuir precisão ou mudar os cálculos.
class IdentificarConsumo {
  const IdentificarConsumo();

  OrigemConsumo registro(RegistroAbastecimento r) {
    if (r.medido) {
      if (r.tipoConsumo == 'medidoMisto') {
        return const OrigemConsumo(
          TipoOrigemConsumo.mistura,
          'Medido com mistura no período',
          'Ciclo entre tanques cheios com mistura de combustíveis. O resultado vale para o conjunto do período.',
        );
      }
      return const OrigemConsumo(
        TipoOrigemConsumo.medido,
        'Medido entre tanques cheios',
        'Usa a distância e os litros de um ciclo completo, incluindo os abastecimentos parciais.',
      );
    }
    switch (r.tipoConsumo) {
      case 'referencia':
        return const OrigemConsumo(
          TipoOrigemConsumo.referencia,
          'Referência inicial',
          'Este registro inicia o histórico e ainda não mede um intervalo de consumo.',
        );
      case 'estimado':
        return const OrigemConsumo(
          TipoOrigemConsumo.estimado,
          'Estimado pela Ficha',
          'Usa a referência de consumo da Ficha. Os litros desta compra não representam o combustível gasto no intervalo.',
        );
      case 'legado':
        return const OrigemConsumo(
          TipoOrigemConsumo.legado,
          'Método anterior',
          'Registro anterior à medição entre tanques cheios, mantido no histórico.',
        );
      default:
        return const OrigemConsumo(
          TipoOrigemConsumo.indisponivel,
          'Medição indisponível',
          'Faltam dados válidos para identificar uma medição neste registro.',
        );
    }
  }

  OrigemConsumo? custoHistorico(List<RegistroAbastecimento> historico) {
    final medidos = historico.where((r) => r.medido).toList();
    if (medidos.isEmpty) return null;
    final mistos = medidos.where((r) => r.tipoConsumo == 'medidoMisto').length;
    final titulo = medidos.length == 1
        ? 'Medido entre tanques cheios'
        : 'Média de ${medidos.length} períodos medidos';
    return OrigemConsumo(
      mistos == 0 ? TipoOrigemConsumo.medido : TipoOrigemConsumo.mistura,
      titulo,
      mistos == 0
          ? 'Custo do histórico calculado pelos períodos completos de medição.'
          : 'Inclui $mistos ${mistos == 1 ? 'período com mistura' : 'períodos com mistura'} de combustíveis. As médias de gasolina e álcool usam apenas os ciclos sem mistura.',
    );
  }

  String gasolina(List<RegistroAbastecimento> historico) {
    final n = historico
        .where(
          (r) =>
              r.medido &&
              r.tipoConsumo == 'medido' &&
              r.combustivelMedido == Combustivel.gasolina,
        )
        .length;
    return n == 0
        ? 'Gasolina estimada pela referência da Ficha.'
        : 'Gasolina medida em $n ${n == 1 ? 'ciclo completo' : 'ciclos completos'} sem mistura.';
  }
}
