import 'package:flutter/material.dart';
import 'package:life_and_roads/core/config/ambiente.dart';
import 'package:life_and_roads/core/legal/textos.dart';
import 'package:life_and_roads/features/ficha/presentation/widgets/campo_oficina.dart';
import 'package:life_and_roads/tema.dart';

/// Seção "Conta (opcional)" da Ficha: entrar, cadastrar, esqueci a senha,
/// trocar senha, sair, excluir. Os controllers e as ações ficam com a tela.
class BlocoConta extends StatelessWidget {
  const BlocoConta({
    super.key,
    required this.logado,
    required this.email,
    required this.reenviar,
    required this.emailCtrl,
    required this.senhaCtrl,
    required this.senhaAtualCtrl,
    required this.senhaNovaCtrl,
    required this.servidorCtrl,
    required this.aoEntrar,
    required this.aoCadastrar,
    required this.aoSair,
    required this.aoTrocarSenha,
    required this.aoEsqueciSenha,
    required this.aoExcluirConta,
    required this.aoMostrarTexto,
    this.chave,
  });

  /// Muda quando a tela quer reabrir o bloco já expandido.
  final Key? chave;

  final bool logado;
  final String? email;

  /// Há fila local esperando a API.
  final bool reenviar;

  final TextEditingController emailCtrl;
  final TextEditingController senhaCtrl;
  final TextEditingController senhaAtualCtrl;
  final TextEditingController senhaNovaCtrl;
  final TextEditingController servidorCtrl;

  final VoidCallback aoEntrar;
  final VoidCallback aoCadastrar;
  final VoidCallback aoSair;
  final VoidCallback aoTrocarSenha;

  /// Abre a folha de recuperação, com o e-mail digitado aqui.
  final VoidCallback aoEsqueciSenha;
  final VoidCallback aoExcluirConta;
  final void Function(String titulo, String corpo) aoMostrarTexto;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: chave,
        initiallyExpanded: chave != null,
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        leading: const Icon(Icons.lock_outline, color: Oficina.latao),
        title: Text(
          logado ? (email ?? 'Conta') : 'Conta (opcional)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          logado
              ? (reenviar
                    ? 'Ficha neste aparelho. Reenvia quando a API voltar.'
                    : 'Ficha sincroniza com o servidor')
              : 'Evita perder a ficha ao trocar de celular.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        children: [
          if (logado) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(onPressed: aoSair, child: const Text('Sair')),
            ),
            CampoOficina(senhaAtualCtrl, 'Senha atual', max: 72, senha: true),
            CampoOficina(
              senhaNovaCtrl,
              'Senha nova (mín. 8)',
              max: 72,
              senha: true,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FilledButton(
                  onPressed: aoTrocarSenha,
                  child: const Text('Trocar senha'),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: aoExcluirConta,
                child: const Text('Excluir conta no servidor'),
              ),
            ),
          ] else ...[
            if (Ambiente.exibeCampoServidor)
              CampoOficina(
                servidorCtrl,
                'Servidor (http://IP:3001 no celular)',
                max: 120,
                teclado: TextInputType.url,
              ),
            CampoOficina(
              emailCtrl,
              'E-mail da conta',
              max: 255,
              teclado: TextInputType.emailAddress,
            ),
            CampoOficina(senhaCtrl, 'Senha (mín. 8)', max: 72, senha: true),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: aoCadastrar,
                    child: const Text('Cadastrar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: aoEntrar,
                    child: const Text('Entrar'),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: aoEsqueciSenha,
                child: const Text('Esqueci a senha'),
              ),
            ),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => aoMostrarTexto('Termos de uso', termosResumo),
              child: const Text('Termos de uso'),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => aoMostrarTexto('Privacidade', privacidadeResumo),
              child: const Text('Privacidade'),
            ),
          ),
        ],
      ),
    );
  }
}
