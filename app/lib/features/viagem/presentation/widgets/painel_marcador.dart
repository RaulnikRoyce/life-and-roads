import 'package:flutter/material.dart';
import 'package:life_and_roads/features/ficha/domain/ficha_moto.dart';
import 'package:life_and_roads/features/viagem/domain/usecases/calibrar_marcador.dart';
import 'package:life_and_roads/tema.dart';
import 'package:life_and_roads/viagem/calculo.dart';

class PainelMarcador extends StatefulWidget {
  const PainelMarcador({
    super.key,
    required this.ficha,
    required this.historico,
  });
  final FichaMoto? ficha;
  final List<RegistroAbastecimento> historico;
  @override
  State<PainelMarcador> createState() => _PainelMarcadorState();
}

class _PainelMarcadorState extends State<PainelMarcador> {
  int? _total, _nivel;
  @override
  void didUpdateWidget(PainelMarcador oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (referenciaMarcadorDaFicha(oldWidget.ficha) !=
        referenciaMarcadorDaFicha(widget.ficha)) {
      _total = null;
      _nivel = null;
    }
  }

  String _litros(double n) => n.toStringAsFixed(1).replaceAll('.', ',');

  @override
  Widget build(BuildContext context) {
    final referencia = referenciaMarcadorDaFicha(widget.ficha);
    int? sugerido;
    for (final r in widget.historico) {
      if (r.referenciaMarcador == referencia &&
          r.totalBarras != null &&
          r.totalBarras! >= 1 &&
          r.totalBarras! <= 30) {
        sugerido = r.totalBarras;
        break;
      }
    }
    final total = _total ?? sugerido;
    final nivel = _nivel != null && total != null && _nivel! <= total
        ? _nivel
        : null;
    final calibracao = total == null
        ? const CalibracaoMarcador()
        : const CalibrarMarcador().executar(
            ficha: widget.ficha,
            historico: widget.historico,
            totalBarras: total,
          );
    final faixa = nivel == null ? null : calibracao.consultar(nivel);
    final amostras = calibracao.niveis[nivel]?.referencias ?? 0;
    return CartaoOficina(
      child: Material(
        color: Colors.transparent,
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Combustível pelas barrinhas'),
          subtitle: const Text('Aprender e consultar a estimativa desta moto'),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                if (referencia == null)
                  const Text(
                    'Preencha a moto e a capacidade do tanque na Ficha para começar a calibração.',
                  )
                else ...[
                  const Text(
                    'O app aprende com os litros que entram quando você completa o tanque. Registre as barras antes e depois, com a moto na mesma posição.',
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    key: ValueKey('total-$referencia-$total'),
                    initialValue: total,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Total de barras do marcador',
                    ),
                    items: [
                      for (var i = 1; i <= 30; i++)
                        DropdownMenuItem(value: i, child: Text('$i barras')),
                    ],
                    onChanged: (v) => setState(() {
                      _total = v;
                      _nivel = null;
                    }),
                  ),
                  const SizedBox(height: 12),
                  if (total != null)
                    DropdownButtonFormField<int>(
                      key: ValueKey('nivel-$referencia-$total-$nivel'),
                      initialValue: nivel,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Barras acesas agora',
                      ),
                      items: [
                        for (var i = 0; i <= total; i++)
                          DropdownMenuItem(
                            value: i,
                            child: Text('$i de $total barras'),
                          ),
                      ],
                      onChanged: (v) => setState(() => _nivel = v),
                    ),
                  const SizedBox(height: 12),
                  if (calibracao.contraditoria)
                    const Text(
                      'As leituras registradas se contradizem. Confira os litros e as barras nos abastecimentos antes de usar a estimativa.',
                    )
                  else if (faixa != null) ...[
                    Text(
                      faixa.minimo == faixa.maximo
                          ? 'Cerca de ${_litros(faixa.minimo)} L no tanque'
                          : 'Faixa observada de ${_litros((faixa.minimo * 10).floor() / 10)} a ${_litros((faixa.maximo * 10).ceil() / 10)} L no tanque',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Estimativa baseada em ${faixa.referencias} abastecimentos completos neste nível. A faixa resume os valores observados; pode haver valores fora dela.',
                    ),
                  ] else if (nivel != null)
                    Text(
                      'Em aprendizado para este nível. $amostras de ${CalibrarMarcador.minimoReferencias} referências necessárias. Complete o tanque a partir dessa leitura e registre as barrinhas.',
                    ),
                  if (nivel == null && !calibracao.contraditoria)
                    const Text(
                      'Escolha a leitura atual para consultar os níveis aprendidos. O aprendizado começa com os novos registros desta moto.',
                    ),
                  const SizedBox(height: 8),
                  const Text(
                    'A capacidade da Ficha é a referência. Inclinação, sensor e nível de enchimento podem mudar a leitura. Zero barras pode ainda ter combustível. O consumo continua sendo medido entre tanques cheios.',
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
