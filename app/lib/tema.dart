import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta da logo: preto, cinza das faixas, vinho, branco das letras.
/// Vinho da UI é um pouco mais claro que o da logo — senão some no asfalto.
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

ThemeData temaOficina() {
  final esquema = const ColorScheme.dark(
    surface: Oficina.asfalto,
    onSurface: Oficina.creme,
    primary: Oficina.latao,
    onPrimary: Oficina.creme,
    secondary: Oficina.ferrugem,
    onSecondary: Oficina.creme,
    error: Oficina.ferrugem,
    onError: Oficina.creme,
    outline: Color(0xFF3A3A3A),
    surfaceContainerHighest: Oficina.couro,
  );

  final texto = TextTheme(
    headlineSmall: GoogleFonts.oswald(
      fontSize: 26,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
      color: Oficina.creme,
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
      color: Oficina.creme,
    ),
    bodyLarge: GoogleFonts.sourceSans3(
      fontSize: 16,
      height: 1.4,
      color: Oficina.tinta,
    ),
    bodyMedium: GoogleFonts.sourceSans3(
      fontSize: 14,
      height: 1.45,
      color: Oficina.tinta,
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
    brightness: Brightness.dark,
    colorScheme: esquema,
    scaffoldBackgroundColor: Oficina.asfalto,
    textTheme: texto,
    splashFactory: InkRipple.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: Oficina.asfalto,
      foregroundColor: Oficina.creme,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.oswald(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.0,
        color: Oficina.creme,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Oficina.faixa,
      indicatorColor: Oficina.latao.withValues(alpha: 0.28),
      elevation: 0,
      height: 72,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final ativo = states.contains(WidgetState.selected);
        return GoogleFonts.oswald(
          fontSize: 11,
          letterSpacing: 0.4,
          color: ativo ? Oficina.latao : Oficina.mute,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final ativo = states.contains(WidgetState.selected);
        return IconThemeData(
          color: ativo ? Oficina.latao : Oficina.mute,
          size: 24,
        );
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Oficina.couro,
      labelStyle: const TextStyle(color: Oficina.mute),
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
        foregroundColor: Oficina.creme,
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
        foregroundColor: Oficina.creme,
        side: const BorderSide(color: Color(0xFF4A3030)),
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
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        visualDensity: VisualDensity.standard,
        tapTargetSize: MaterialTapTargetSize.padded,
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Oficina.creme;
          return Oficina.tinta;
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Oficina.latao;
          return Oficina.couro;
        }),
        side: WidgetStateProperty.all(BorderSide.none),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Oficina.couro,
      contentTextStyle: GoogleFonts.sourceSans3(color: Oficina.creme),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Oficina.couro,
        border: campo,
        enabledBorder: campo,
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Oficina.latao,
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: Oficina.couro,
      headerBackgroundColor: Oficina.asfalto,
      headerForegroundColor: Oficina.latao,
    ),
    dividerColor: Colors.transparent,
    expansionTileTheme: const ExpansionTileThemeData(
      iconColor: Oficina.latao,
      collapsedIconColor: Oficina.mute,
      shape: Border(),
      collapsedShape: Border(),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Oficina.couro,
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
          color: Oficina.couro,
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
        color: Oficina.couro,
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
