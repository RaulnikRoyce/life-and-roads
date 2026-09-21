import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:life_and_roads/core/widgets/movimento.dart';
import 'package:life_and_roads/features/auth/domain/usecases/redefinir_senha.dart';
import 'package:life_and_roads/features/ficha/presentation/widgets/campo_oficina.dart';

/// Pede o código para o e-mail. Devolve null quando foi, ou a mensagem
/// de erro que a folha mostra.
typedef EnviarCodigo = Future<String?> Function(String email);

/// Troca a senha com o código. Devolve null quando trocou, ou a mensagem
/// de erro que a folha mostra.
typedef RedefinirComCodigo = Future<String?> Function(
  String email,
  String codigo,
  String senhaNova,
);

/// Folha "Esqueci a senha" em dois passos: e-mail, depois código e senha
/// nova. Sucesso no passo 1 avança; sucesso no passo 2 fecha a folha.
///
/// Dona dos próprios controllers, como a FolhaData: eles só são
/// descartados quando a folha sai da árvore, depois da animação de fechar.
/// A mensagem de erro aparece aqui dentro porque o snackbar da tela fica
/// atrás da folha.
class FolhaRecuperarSenha extends StatefulWidget {
  const FolhaRecuperarSenha({
    super.key,
    required this.emailInicial,
    required this.aoEnviar,
    required this.aoRedefinir,
  });

  final String emailInicial;
  final EnviarCodigo aoEnviar;
  final RedefinirComCodigo aoRedefinir;

  static Future<void> abrir(
    BuildContext context, {
    required String emailInicial,
    required EnviarCodigo aoEnviar,
    required RedefinirComCodigo aoRedefinir,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => FolhaRecuperarSenha(
        emailInicial: emailInicial,
        aoEnviar: aoEnviar,
        aoRedefinir: aoRedefinir,
      ),
    );
  }

  @override
  State<FolhaRecuperarSenha> createState() => _FolhaRecuperarSenhaState();
}

class _FolhaRecuperarSenhaState extends State<FolhaRecuperarSenha> {
  static const _regras = RedefinirSenha();

  late final TextEditingController _email = TextEditingController(
    text: widget.emailInicial,
  );
  final _codigo = TextEditingController();
  final _senha = TextEditingController();

  int _passo = 1;
  bool _ocupado = false;
  String? _erro;

  /// Quantos códigos esta folha pediu. Muda o texto do passo 2.
  int _enviados = 0;

  @override
  void dispose() {
    _email.dispose();
    _codigo.dispose();
    _senha.dispose();
    super.dispose();
  }

  String get _emailLimpo => _email.text.trim().toLowerCase();

  Future<void> _enviar() async {
    setState(() {
      _ocupado = true;
      _erro = null;
    });
    final erro = await widget.aoEnviar(_emailLimpo);
    if (!mounted) return;
    setState(() {
      _ocupado = false;
      _erro = erro;
      if (erro == null) {
        _enviados++;
        _passo = 2;
      }
    });
  }

  Future<void> _redefinir() async {
    setState(() {
      _ocupado = true;
      _erro = null;
    });
    final erro = await widget.aoRedefinir(
      _emailLimpo,
      _codigo.text.trim(),
      _senha.text,
    );
    if (!mounted) return;
    if (erro == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _ocupado = false;
      _erro = erro;
    });
  }

  /// O passo 2 não tem campo de e-mail, então ele precisa estar válido
  /// antes de avançar; senão o piloto ficaria preso lá com o erro.
  void _pularParaCodigo() {
    final erro = _regras.validarEmail(_emailLimpo);
    setState(() {
      _erro = erro;
      if (erro == null) _passo = 2;
    });
  }

  String get _textoPasso2 {
    if (_enviados == 0) {
      return 'Digite o código que chegou em $_emailLimpo e a senha nova.';
    }
    if (_enviados == 1) {
      return 'Código enviado para $_emailLimpo, se esse e-mail tiver conta. '
          'Vale 15 minutos.';
    }
    return 'Código novo enviado para $_emailLimpo, se esse e-mail tiver '
        'conta. O anterior deixou de valer.';
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        16 +
            MediaQuery.viewInsetsOf(context).bottom +
            MediaQuery.paddingOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recuperar senha', style: tema.textTheme.titleMedium),
            const SizedBox(height: 2),
            Text('$_passo de 2', style: tema.textTheme.bodyMedium),
            const SizedBox(height: 12),
            EntradaSuave(
              chave: _passo,
              duracao: Movimento.curto,
              child: _passo == 1 ? _passoEmail(tema) : _passoCodigo(tema),
            ),
          ],
        ),
      ),
    );
  }

  Widget _passoEmail(ThemeData tema) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Um código de 6 dígitos vai para o e-mail da conta. Vale 15 minutos.',
          style: tema.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        CampoOficina(
          _email,
          'E-mail da conta',
          max: 255,
          teclado: TextInputType.emailAddress,
        ),
        _textoErro(tema),
        FilledButton(
          onPressed: _ocupado ? null : _enviar,
          child: const Text('Enviar código'),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: _ocupado ? null : _pularParaCodigo,
            child: const Text('Já tenho o código'),
          ),
        ),
      ],
    );
  }

  Widget _passoCodigo(ThemeData tema) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_textoPasso2, style: tema.textTheme.bodyMedium),
        const SizedBox(height: 12),
        CampoOficina(
          _codigo,
          'Código de 6 dígitos',
          max: 6,
          teclado: TextInputType.number,
          filtros: [FilteringTextInputFormatter.digitsOnly],
        ),
        CampoOficina(_senha, 'Senha nova (mín. 8)', max: 72, senha: true),
        _textoErro(tema),
        FilledButton(
          onPressed: _ocupado ? null : _redefinir,
          child: const Text('Redefinir senha'),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: _ocupado ? null : _enviar,
            child: const Text('Enviar de novo'),
          ),
        ),
      ],
    );
  }

  Widget _textoErro(ThemeData tema) {
    final erro = _erro;
    if (erro == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        erro,
        style: tema.textTheme.bodyMedium?.copyWith(
          color: tema.colorScheme.error,
        ),
      ),
    );
  }
}
