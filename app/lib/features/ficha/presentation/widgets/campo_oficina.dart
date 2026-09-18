import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Campo de texto padrão da Ficha: rótulo flutuante, sem contador.
class CampoOficina extends StatelessWidget {
  const CampoOficina(
    this.controller,
    this.rotulo, {
    super.key,
    this.teclado,
    this.linhas = 1,
    this.max = 80,
    this.senha = false,
    this.filtros,
  });

  final TextEditingController controller;
  final String rotulo;
  final TextInputType? teclado;
  final int linhas;
  final int max;
  final bool senha;
  final List<TextInputFormatter>? filtros;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: teclado,
        maxLines: senha ? 1 : linhas,
        maxLength: max,
        obscureText: senha,
        inputFormatters: filtros,
        decoration: InputDecoration(labelText: rotulo, counterText: ''),
      ),
    );
  }
}
