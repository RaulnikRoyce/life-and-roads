import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_roads/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ApiCaderneta segurança de transporte', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('definirBase rejeita HTTP para hosts remotos', () async {
      expect(
        () => ApiCaderneta.definirBase('http://192.168.1.100:3001'),
        throwsA(isA<FalhaApi>()),
      );
    });

    test('definirBase aceita HTTPS para hosts remotos', () async {
      await ApiCaderneta.definirBase('https://api.example.com');
      expect(ApiCaderneta.base, 'https://api.example.com');
    });

    test('definirBase aceita HTTP para localhost', () async {
      await ApiCaderneta.definirBase('http://localhost:3001');
      expect(ApiCaderneta.base, 'http://localhost:3001');
    });

    test('definirBase aceita HTTP para 127.0.0.1', () async {
      await ApiCaderneta.definirBase('http://127.0.0.1:3001');
      expect(ApiCaderneta.base, 'http://127.0.0.1:3001');
    });

    test('definirBase rejeita protocolos inválidos', () async {
      expect(
        () => ApiCaderneta.definirBase('ftp://example.com'),
        throwsA(isA<FalhaApi>()),
      );
    });

    test('carregarBase remove URLs HTTP inseguras salvas', () async {
      // Simula uma URL HTTP insegura salva anteriormente
      SharedPreferences.setMockInitialValues({
        'api_base_v1': 'http://192.168.1.100:3001',
      });
      
      await ApiCaderneta.carregarBase();
      
      // Deve voltar ao padrão e remover a URL insegura
      expect(ApiCaderneta.base, ApiCaderneta.padrao);
      
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('api_base_v1'), isNull);
    });

    test('carregarBase mantém URLs HTTPS seguras salvas', () async {
      SharedPreferences.setMockInitialValues({
        'api_base_v1': 'https://api.example.com',
      });
      
      await ApiCaderneta.carregarBase();
      
      expect(ApiCaderneta.base, 'https://api.example.com');
    });
  });
}
