/// Um disparo local às 9h (Brasília no aparelho). Sem plugin aqui.
class DisparoLembrete {
  const DisparoLembrete({
    required this.id,
    required this.quando,
    required this.titulo,
    required this.corpo,
  });

  final int id;
  final DateTime quando;
  final String titulo;
  final String corpo;
}

/// Data passada vira amanhã 9h. Se falta mais de 7 dias, agenda também a semana.
class MontarHorariosLembrete {
  const MontarHorariosLembrete();

  static const idOleo = 1;
  static const idPneus = 2;
  static const idIpva = 3;
  static const idSeguro = 4;
  static const idLicenciamento = 5;
  static const idCnh = 6;
  static const idOleoSemana = 11;
  static const idPneusSemana = 12;
  static const idIpvaSemana = 13;
  static const idSeguroSemana = 14;
  static const idLicenciamentoSemana = 15;
  static const idCnhSemana = 16;

  List<DisparoLembrete> executar({
    required DateTime agora,
    DateTime? oleo,
    DateTime? pneus,
    DateTime? ipva,
    DateTime? seguro,
    DateTime? licenciamento,
    DateTime? cnh,
  }) {
    return [
      ..._de(
        agora: agora,
        idDia: idOleo,
        idSemana: idOleoSemana,
        dia: oleo,
        titulo: 'Óleo da moto',
        corpoHoje: 'Hoje vence a troca de óleo.',
        corpoPassou: 'Já passou a troca de óleo. Confira na Manutenção.',
        corpoSemana: 'Falta uma semana para a troca de óleo.',
      ),
      ..._de(
        agora: agora,
        idDia: idPneus,
        idSemana: idPneusSemana,
        dia: pneus,
        titulo: 'Pneus da moto',
        corpoHoje: 'Hoje vence a troca de pneus.',
        corpoPassou: 'Já passou a troca de pneus. Confira na Manutenção.',
        corpoSemana: 'Falta uma semana para a troca de pneus.',
      ),
      ..._de(
        agora: agora,
        idDia: idIpva,
        idSemana: idIpvaSemana,
        dia: ipva,
        titulo: 'IPVA',
        corpoHoje: 'Hoje vence o IPVA.',
        corpoPassou: 'Já passou o IPVA. Confira na Manutenção.',
        corpoSemana: 'Falta uma semana para o IPVA.',
      ),
      ..._de(
        agora: agora,
        idDia: idSeguro,
        idSemana: idSeguroSemana,
        dia: seguro,
        titulo: 'Seguro',
        corpoHoje: 'Hoje vence o seguro.',
        corpoPassou: 'Já passou o seguro. Confira na Manutenção.',
        corpoSemana: 'Falta uma semana para o seguro.',
      ),
      ..._de(
        agora: agora,
        idDia: idLicenciamento,
        idSemana: idLicenciamentoSemana,
        dia: licenciamento,
        titulo: 'Licenciamento',
        corpoHoje: 'Hoje vence o licenciamento.',
        corpoPassou: 'Já passou o licenciamento. Confira na Manutenção.',
        corpoSemana: 'Falta uma semana para o licenciamento.',
      ),
      ..._de(
        agora: agora,
        idDia: idCnh,
        idSemana: idCnhSemana,
        dia: cnh,
        titulo: 'CNH',
        corpoHoje: 'Hoje vence a CNH.',
        corpoPassou: 'Já passou a CNH. Confira na Manutenção.',
        corpoSemana: 'Falta uma semana para a CNH.',
      ),
    ];
  }

  List<DisparoLembrete> _de({
    required DateTime agora,
    required int idDia,
    required int idSemana,
    required DateTime? dia,
    required String titulo,
    required String corpoHoje,
    required String corpoPassou,
    required String corpoSemana,
  }) {
    if (dia == null) return const [];
    final nove = DateTime(dia.year, dia.month, dia.day, 9);
    if (!nove.isAfter(agora)) {
      final amanha = DateTime(agora.year, agora.month, agora.day, 9)
          .add(const Duration(days: 1));
      return [
        DisparoLembrete(
          id: idDia,
          quando: amanha,
          titulo: titulo,
          corpo: corpoPassou,
        ),
      ];
    }

    final hoje = DateTime(agora.year, agora.month, agora.day);
    final alvo = DateTime(dia.year, dia.month, dia.day);
    final faltam = alvo.difference(hoje).inDays;
    final lista = <DisparoLembrete>[
      DisparoLembrete(
        id: idDia,
        quando: nove,
        titulo: titulo,
        corpo: corpoHoje,
      ),
    ];
    if (faltam > 7) {
      final semana = DateTime(alvo.year, alvo.month, alvo.day, 9)
          .subtract(const Duration(days: 7));
      if (semana.isAfter(agora)) {
        lista.add(
          DisparoLembrete(
            id: idSemana,
            quando: semana,
            titulo: titulo,
            corpo: corpoSemana,
          ),
        );
      }
    }
    return lista;
  }
}
