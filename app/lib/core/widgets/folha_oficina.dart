import 'package:flutter/material.dart';
import 'package:life_and_roads/tema.dart';

/// Tema para o que fica sobre o fundo de cartão (a folha, o CartaoOficina).
/// A cor de cartão vira a cor do fundo da tela, para o campo de texto e a
/// LinhaData voltarem a aparecer em vez de sumir no fundo.
ThemeData temaSobreCartao(ThemeData tema) => tema.copyWith(
  colorScheme: tema.colorScheme.copyWith(
    surfaceContainerHighest: tema.scaffoldBackgroundColor,
  ),
  inputDecorationTheme: tema.inputDecorationTheme.copyWith(
    fillColor: tema.scaffoldBackgroundColor,
  ),
);

/// Folha que sobe com puxador, título, subtítulo, [campos] e o botão de
/// confirmar. Fecha só quando [aoConfirmar] devolve true. O que foi digitado
/// fica em memória ao fechar sem confirmar.
///
/// O Scaffold dentro da folha faz o snackbar aparecer por cima dela (o
/// ScaffoldMessenger mostra em todo Scaffold registrado).
///
/// Enquanto confirma (com conta, espera a rede) o botão fica travado e mostra
/// [rotuloOcupado], para um segundo toque não gravar de novo nem dar um pop a
/// mais. Só fecha se a folha ainda é a rota de cima; um pop fora de hora
/// tiraria a tela principal. Mesmo padrão da folha de grupo da Manutenção.
Future<void> abrirFolhaOficina(
  BuildContext context, {
  required String titulo,
  required String subtitulo,
  required List<Widget> Function(StateSetter folha) campos,
  required String acao,
  required Future<bool> Function() aoConfirmar,
  String rotuloOcupado = 'Salvando',
}) async {
  final tema = Theme.of(context);
  final temaFolha = temaSobreCartao(tema);
  var ocupado = false;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.96,
      builder: (ctx, rolagem) => StatefulBuilder(
        builder: (ctx, setFolha) => Theme(
          data: temaFolha,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: ListView(
              controller: rolagem,
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                24 + MediaQuery.paddingOf(ctx).bottom,
              ),
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Oficina.mute.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(titulo, style: tema.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(subtitulo, style: tema.textTheme.bodyMedium),
                const SizedBox(height: 16),
                ...campos(setFolha),
                const SizedBox(height: 4),
                FilledButton(
                  onPressed: ocupado
                      ? null
                      : () async {
                          setFolha(() => ocupado = true);
                          final ok = await aoConfirmar();
                          if (!ctx.mounted) return;
                          final noTopo = ModalRoute.of(ctx)?.isCurrent ?? false;
                          if (ok && noTopo) {
                            Navigator.of(ctx).pop();
                          } else {
                            setFolha(() => ocupado = false);
                          }
                        },
                  // Sem indicador em loop (regra do projeto): o texto muda
                  // para não parecer travado.
                  child: Text(ocupado ? rotuloOcupado : acao),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
