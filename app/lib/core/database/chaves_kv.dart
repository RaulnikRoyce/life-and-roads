/// Chaves da tabela KV (antes SharedPreferences, salvo token/tema/URL).
class ChavesKv {
  static const ficha = 'ficha_moto_v1';
  static const agenda = 'manutencao_v1';
  static const extra = 'manutencao_km_v1';
  static const foto = 'foto_moto_v1';
  static const precoGasolina = 'preco_litro_v1';
  static const precoAlcool = 'preco_alcool_v1';
  static const ponto = 'ultimo_ponto_v1';
  static const manutencaoSync = 'manutencao_sync_v1';
  static const fichaConflito = 'ficha_conflito_v1';
  static const agendaConflito = 'agenda_conflito_v1';
  static const avisosLidos = 'avisos_lidos_v1';

  /// Quando o backup automático gravou pela última vez (ISO).
  static const backupAutomaticoEm = 'backup_auto_em_v1';

  /// O piloto dispensou o convite de criar conta.
  static const conviteContaDispensado = 'convite_conta_nao_v1';

  // Caderneta na nuvem (ADR 0038).

  /// `nao` quando o piloto desligou. Sem valor, ligada.
  static const nuvemLigada = 'nuvem_ligada_v1';

  /// O `atualizadoEm` que o servidor devolveu, guardado como veio.
  static const nuvemCarimbo = 'nuvem_carimbo_v1';

  /// sha256 do pacote que está na nuvem, para não mandar o mesmo de novo.
  static const nuvemAssinatura = 'nuvem_assinatura_v1';

  /// `sim` depois de um 409, até o piloto escolher qual caderneta fica.
  static const nuvemConflito = 'nuvem_conflito_v1';

  /// Versão dos termos que a conta aceitou, como a API devolveu.
  static const termosAceitos = 'termos_aceitos_v1';

  static const textos = [
    ficha,
    agenda,
    extra,
    precoGasolina,
    precoAlcool,
    ponto,
    manutencaoSync,
  ];
}
