import 'package:flutter/material.dart';
import 'package:life_and_roads/core/widgets/movimento.dart';
import 'package:life_and_roads/features/viagem/domain/usecases/resumo_consumo.dart';
import 'package:life_and_roads/features/viagem/presentation/widgets/grafico_consumo.dart';
import 'package:life_and_roads/tema.dart';

/// O posto como painel: o custo por km em número grande (o que o piloto mais
/// olha), de onde ele veio, as pastilhas de postos, consumo e tanque, qual
/// bomba vale hoje e a linha do custo por km dos últimos postos.
class PainelPosto extends StatelessWidget {
  const PainelPosto({
    super.key,
    this.custoPorKm,
    required this.origem,
    this.fraseVencedor,
    required this.postos,
    this.kmComUmLitro,
    this.autonomiaKm,
    this.barras = const [],
  });

  /// Reais por km. Média dos postos ou, sem histórico, pela ficha e os
  /// preços do dia.
  final double? custoPorKm;

  /// De onde veio o número ("média de 5 postos").
  final String origem;

  /// "Hoje o álcool custa menos." quando dá para comparar as duas bombas.
  final String? fraseVencedor;

  final int postos;

  /// Km com 1 L: o último posto ou, sem histórico, a ficha.
  final double? kmComUmLitro;

  /// Km com o tanque cheio pelo consumo da ficha.
  final double? autonomiaKm;

  /// Como o histórico entrega, do mais novo ao mais antigo.
  final List<BarraConsumo> barras;

  /// "0,42".
  static String reais(double v) => v.toStringAsFixed(2).replaceAll('.', ',');

  /// "38" ou "38,2": uma casa só quando ela diz algo.
  static String km(double v) {
    final t = v.toStringAsFixed(1);
    final semZero = t.endsWith('.0') ? t.substring(0, t.length - 2) : t;
    return semZero.replaceAll('.', ',');
  }

  /// "32.130".
  static String milhar(num v) {
    final n = v.round().toString();
    final b = StringBuffer();
    for (var i = 0; i < n.length; i++) {
      final resto = n.length - i;
      b.write(n[i]);
      if (resto > 1 && resto % 3 == 1) b.write('.');
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    // As três pastilhas (104 px cada) só cabem ao lado do número a partir
    // de 760 px; abaixo disso vão para baixo dele.
    final estreita = MediaQuery.sizeOf(context).width < 760;
    final grande = tema.textTheme.headlineSmall?.copyWith(
      fontSize: 44,
      height: 1,
    );

    final numero = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'POR KM',
          style: tema.textTheme.labelLarge?.copyWith(
            fontSize: 11,
            letterSpacing: 1.4,
            color: Oficina.mute,
          ),
        ),
        const SizedBox(height: 2),
        if (custoPorKm == null)
          Text('-', style: grande)
        else
          NumeroAnimado(
            valor: custoPorKm!,
            formatar: (v) => 'R\$ ${reais(v)}',
            style: grande,
          ),
        const SizedBox(height: 4),
        Text(
          origem,
          style: tema.textTheme.bodyMedium?.copyWith(color: Oficina.mute),
        ),
      ],
    );

    final pastilhas = Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: estreita ? WrapAlignment.start : WrapAlignment.end,
      children: [
        _Pastilha(
          icone: Icons.local_gas_station_outlined,
          valor: '$postos',
          rotulo: 'POSTOS',
        ),
        _Pastilha(
          icone: Icons.water_drop_outlined,
          valor: kmComUmLitro == null ? '-' : '${km(kmComUmLitro!)} km',
          rotulo: 'COM 1 L',
        ),
        _Pastilha(
          icone: Icons.route_outlined,
          valor: autonomiaKm == null ? '-' : '${milhar(autonomiaKm!)} km',
          rotulo: 'TANQUE CHEIO',
        ),
      ],
    );

    return EntradaSuave(
      child: CartaoOficina(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (estreita) ...[
              numero,
              const SizedBox(height: 14),
              pastilhas,
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: numero),
                  const SizedBox(width: 12),
                  Expanded(child: pastilhas),
                ],
              ),
            if (fraseVencedor != null) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Oficina.latao,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fraseVencedor!,
                      style: tema.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            GraficoConsumo(
              barras: barras,
              fundo: tema.colorScheme.surfaceContainerHighest,
            ),
          ],
        ),
      ),
    );
  }
}

/// Mesma cara da pastilha do painel da moto. Como fica dentro do cartão, o
/// fundo é o da tela (a cor de cartão sumiria no cartão, a regra da folha).
class _Pastilha extends StatelessWidget {
  const _Pastilha({
    required this.icone,
    required this.valor,
    required this.rotulo,
  });

  final IconData icone;
  final String valor;
  final String rotulo;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Container(
      width: 104,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: tema.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 18, color: Oficina.latao),
          const SizedBox(height: 8),
          Text(
            valor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tema.textTheme.titleMedium?.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 2),
          Text(
            rotulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tema.textTheme.labelLarge?.copyWith(
              fontSize: 10,
              letterSpacing: 1.2,
              color: Oficina.mute,
            ),
          ),
        ],
      ),
    );
  }
}
