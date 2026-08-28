import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta derivada da logomarca: preto, cinza das faixas, vinho e branco.
/// O vinho da interface é um pouco mais claro que o da marca, para contraste
/// sobre o fundo escuro.
class Oficina {
  static const asfalto = Color(0xFF121212);
  static const couro = Color(0xFF2A2A2A);
  static const faixa = Color(0xFF1C1C1C);
  static const creme = Color(0xFFF5F5F5);
  static const tinta = Color(0xFFC8C8C8);
  static const latao = Color(0xFF8B4545);
  static const vinho = Color(0xFF663333);
  static const ferrugem = Color(0xFFA35555);
  static const mute = Color(0xFF8A8A8A);
  static const raio = 16.0;
}

ThemeData temaOficina() => _temaOficina(escuro: true);

ThemeData temaOficinaClaro() => _temaOficina(escuro: false);

ThemeData _temaOficina({required bool escuro}) {
  final fundo = escuro ? Oficina.asfalto : const Color(0xFFF4F0EA);
  final cartao = escuro ? Oficina.couro : const Color(0xFFE8E2D8);
  final faixa = escuro ? Oficina.faixa : const Color(0xFFEDE8E0);
  final texto = escuro ? Oficina.creme : const Color(0xFF1A1A1A);
  final tinta = escuro ? Oficina.tinta : const Color(0xFF4A4A4A);
  final mute = escuro ? Oficina.mute : const Color(0xFF6E6E6E);
  final onPrimary = escuro ? Oficina.creme : Colors.white;
  final outline = escuro ? const Color(0xFF3A3A3A) : const Color(0xFFD4CEC4);
  final outlinedSide =
      escuro ? const Color(0xFF4A3030) : const Color(0xFFC4B8B0);

  final esquema = ColorScheme(
    brightness: escuro ? Brightness.dark : Brightness.light,
    surface: fundo,
    onSurface: texto,
    primary: Oficina.latao,
    onPrimary: onPrimary,
    secondary: Oficina.ferrugem,
    onSecondary: onPrimary,
    error: Oficina.ferrugem,
    onError: onPrimary,
    outline: outline,
    surfaceContainerHighest: cartao,
  );

  final textoTema = TextTheme(
    headlineSmall: GoogleFonts.oswald(
      fontSize: 26,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
      color: texto,
    ),
    titleLarge: GoogleFonts.oswald(
      fontSize: 20,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.8,
      color: Oficina.latao,
    ),
    titleMedium: GoogleFonts.sourceSans3(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      height: 1.25,
      color: texto,
    ),
    bodyLarge: GoogleFonts.sourceSans3(
      fontSize: 16,
      height: 1.4,
      color: tinta,
    ),
    bodyMedium: GoogleFonts.sourceSans3(
      fontSize: 14,
      height: 1.45,
      color: tinta,
    ),
    labelLarge: GoogleFonts.oswald(
      fontSize: 12,
      letterSpacing: 1.4,
      fontWeight: FontWeight.w600,
    ),
  );

  final campo = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide.none,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: escuro ? Brightness.dark : Brightness.light,
    colorScheme: esquema,
    scaffoldBackgroundColor: fundo,
    textTheme: textoTema,
    splashFactory: InkRipple.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: fundo,
      foregroundColor: texto,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.oswald(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.0,
        color: texto,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: faixa,
      indicatorColor: Oficina.latao.withValues(alpha: 0.28),
      elevation: 0,
      height: 72,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final ativo = states.contains(WidgetState.selected);
        return GoogleFonts.oswald(
          fontSize: 11,
          letterSpacing: 0.4,
          color: ativo ? Oficina.latao : mute,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final ativo = states.contains(WidgetState.selected);
        return IconThemeData(
          color: ativo ? Oficina.latao : mute,
          size: 24,
        );
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cartao,
      labelStyle: TextStyle(color: mute),
      floatingLabelStyle: const TextStyle(color: Oficina.latao),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: campo,
      enabledBorder: campo,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Oficina.latao, width: 1.4),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Oficina.latao,
        foregroundColor: onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        minimumSize: const Size.fromHeight(52),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Oficina.raio),
        ),
        textStyle: GoogleFonts.oswald(
          fontSize: 16,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: texto,
        side: BorderSide(color: outlinedSide),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Oficina.raio),
        ),
        textStyle: GoogleFonts.oswald(
          fontSize: 15,
          letterSpacing: 0.6,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: Oficina.latao),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: cartao,
      selectedColor: Oficina.latao.withValues(alpha: 0.2),
      labelStyle: GoogleFonts.sourceSans3(color: texto, fontSize: 13),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        visualDensity: VisualDensity.standard,
        tapTargetSize: MaterialTapTargetSize.padded,
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return onPrimary;
          return tinta;
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Oficina.latao;
          return cartao;
        }),
        side: WidgetStateProperty.all(BorderSide.none),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: cartao,
      contentTextStyle: GoogleFonts.sourceSans3(color: texto),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cartao,
        border: campo,
        enabledBorder: campo,
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Oficina.latao,
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: cartao,
      headerBackgroundColor: fundo,
      headerForegroundColor: Oficina.latao,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: cartao,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    dividerColor: Colors.transparent,
    expansionTileTheme: ExpansionTileThemeData(
      iconColor: Oficina.latao,
      collapsedIconColor: mute,
      shape: const Border(),
      collapsedShape: const Border(),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: cartao,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Oficina.raio),
      ),
    ),
  );
}

/// Título de seção: letra grande + traço vinho.
class TituloOficina extends StatelessWidget {
  const TituloOficina(this.titulo, {super.key, this.subtitulo});

  final String titulo;
  final String? subtitulo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 3,
          decoration: BoxDecoration(
            color: Oficina.latao,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        if (subtitulo != null) ...[
          const SizedBox(height: 12),
          Text(subtitulo!, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ],
    );
  }
}

EdgeInsets paddingOficina(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  final lateral = w < 600 ? 20.0 : 28.0;
  return EdgeInsets.fromLTRB(lateral, 8, lateral, 32);
}

bool telaEstreita(BuildContext context) => MediaQuery.sizeOf(context).width < 480;

class CartaoOficina extends StatelessWidget {
  const CartaoOficina({
    required this.child,
    super.key,
    this.destaque = false,
  });

  final Widget child;
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Oficina.raio),
      child: SizedBox(
        width: double.infinity,
        child: ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(destaque ? 21 : 18, 18, 18, 18),
                child: child,
              ),
              if (destaque)
                const Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 3,
                  child: ColoredBox(color: Oficina.latao),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class DuplaCampos extends StatelessWidget {
  const DuplaCampos({
    required this.esquerda,
    required this.direita,
    super.key,
  });

  final Widget esquerda;
  final Widget direita;

  @override
  Widget build(BuildContext context) {
    if (telaEstreita(context)) {
      return Column(children: [esquerda, direita]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: esquerda),
        const SizedBox(width: 12),
        Expanded(child: direita),
      ],
    );
  }
}

class StatOficina extends StatelessWidget {
  const StatOficina(this.rotulo, this.valor, {super.key});

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            rotulo,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 11,
                  letterSpacing: 1.1,
                  color: Oficina.mute,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            valor,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

/// Data compacta: rótulo + valor, sem cara de planilha.
class LinhaData extends StatelessWidget {
  const LinhaData({
    required this.rotulo,
    required this.valor,
    required this.onTap,
    this.onLimpar,
    super.key,
  });

  final String rotulo;
  final String valor;
  final VoidCallback onTap;
  final VoidCallback? onLimpar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rotulo,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Oficina.mute,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        valor,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                if (onLimpar != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    color: Oficina.mute,
                    onPressed: onLimpar,
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(Icons.event, color: Oficina.latao, size: 20),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
