package com.raulnik.life_and_roads

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private companion object {
        const val CANAL = "life_and_roads/download"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CANAL,
        ).setMethodCallHandler { chamada, resposta ->
            if (chamada.method != "salvar") {
                resposta.notImplemented()
                return@setMethodCallHandler
            }
            val nome = chamada.argument<String>("nome")
            val conteudo = chamada.argument<String>("conteudo")
            if (nome.isNullOrBlank() || conteudo == null) {
                resposta.error("argumento", "nome e conteudo são obrigatórios", null)
                return@setMethodCallHandler
            }
            try {
                resposta.success(GravadorDownload.salvar(this, nome, conteudo))
            } catch (erro: Exception) {
                // Cartão cheio, pasta protegida, política do fabricante. O app
                // segue; quem chamou trata o null.
                resposta.error("gravar", erro.message, null)
            }
        }
    }
}
