import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_roads/core/sync/status_sync.dart';
import 'package:life_and_roads/core/sync/texto_sync.dart';

void main() {
  final carimbo = DateTime(2026, 9, 17, 14, 32); // hora local

  test('em dia mostra o carimbo do servidor', () {
    final t = textoSync(MetadadoSync(remoteUpdatedAt: carimbo));
    expect(t, 'No servidor. Atualizado 17/09 14:32.');
  });

  test('em dia sem carimbo não inventa hora', () {
    expect(textoSync(const MetadadoSync()), 'No servidor.');
  });

  test('fila mostra desde quando e o motivo', () {
    final t = textoSync(
      MetadadoSync(
        status: StatusSync.failed,
        localUpdatedAt: carimbo,
        lastSyncError: 'API fora do ar.',
      ),
    );
    expect(t, 'Aguardando o servidor desde 17/09 14:32. API fora do ar.');
  });

  test('última tentativa falhou sem fila: diz que o servidor não respondeu', () {
    final t = textoSync(MetadadoSync(remoteUpdatedAt: carimbo), offline: true);
    expect(t, 'Sem resposta do servidor. Caderneta neste aparelho.');
  });

  test('conflito fica com o cartão, sem linha', () {
    expect(
      textoSync(const MetadadoSync(status: StatusSync.conflict)),
      isNull,
    );
  });

  test('dataHoraCurta converte UTC para a hora local', () {
    final utc = DateTime.utc(2026, 1, 5, 3, 7);
    expect(dataHoraCurta(utc), dataHoraCurta(utc.toLocal()));
    expect(dataHoraCurta(DateTime(2026, 1, 5, 3, 7)), '05/01 03:07');
  });
}
