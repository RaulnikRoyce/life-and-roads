import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:life_and_roads/tema.dart';

/// Foto no topo do cartão da moto. Toque escolhe, toque longo apaga.
class FotoDaMoto extends StatelessWidget {
  const FotoDaMoto({
    super.key,
    required this.foto,
    required this.aoEscolher,
    required this.aoApagar,
  });

  final Uint8List? foto;
  final VoidCallback aoEscolher;
  final VoidCallback aoApagar;

  @override
  Widget build(BuildContext context) {
    final bytes = foto;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 196,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (bytes != null)
              Image.memory(bytes, fit: BoxFit.cover)
            else
              ColoredBox(
                color: Oficina.asfalto,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.two_wheeler,
                      color: Oficina.latao,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Adicionar foto',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: aoEscolher,
                onLongPress: bytes == null ? null : aoApagar,
                child: const SizedBox.expand(),
              ),
            ),
            if (bytes != null)
              Positioned(
                right: 8,
                top: 8,
                child: IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: Oficina.asfalto.withValues(alpha: 0.7),
                    foregroundColor: Oficina.creme,
                    visualDensity: VisualDensity.compact,
                  ),
                  tooltip: 'Remover foto',
                  onPressed: aoApagar,
                  icon: const Icon(Icons.close, size: 18),
                ),
              ),
            Positioned(
              right: 8,
              bottom: 8,
              child: IgnorePointer(
                child: Icon(
                  Icons.photo_camera_outlined,
                  color: Oficina.latao.withValues(alpha: 0.9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
