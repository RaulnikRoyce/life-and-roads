package com.raulnik.life_and_roads

import android.content.ContentValues
import android.content.Context
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import java.io.File

/**
 * Grava o backup da caderneta na pasta Download, sempre no mesmo arquivo.
 *
 * Do Android 10 em diante usa a MediaStore, que é a forma sancionada de
 * escrever em Download sem pedir permissão. Antes disso escreve direto,
 * porque o armazenamento ainda era aberto.
 *
 * O arquivo fica fora da pasta do app de propósito: ele precisa sobreviver
 * a desinstalar o app e a trocar de celular.
 */
object GravadorDownload {
    private const val PASTA = "life.and.roads"

    /** Devolve o caminho que o piloto vê, ou null se não deu para gravar. */
    fun salvar(contexto: Context, nome: String, conteudo: String): String? {
        val bytes = conteudo.toByteArray(Charsets.UTF_8)
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            salvarPelaMediaStore(contexto, nome, bytes)
        } else {
            salvarDireto(nome, bytes)
        }
    }

    private fun salvarPelaMediaStore(
        contexto: Context,
        nome: String,
        bytes: ByteArray,
    ): String? {
        val relativo = "${Environment.DIRECTORY_DOWNLOADS}/$PASTA"
        val resolver = contexto.contentResolver
        val colecao = MediaStore.Downloads.EXTERNAL_CONTENT_URI

        // Mesmo nome sempre: acha o de antes e regrava, senão o Android
        // cria backup(1).json, backup(2).json e o piloto não sabe qual vale.
        val existente = resolver.query(
            colecao,
            arrayOf(MediaStore.Downloads._ID),
            "${MediaStore.Downloads.RELATIVE_PATH} LIKE ? AND " +
                "${MediaStore.Downloads.DISPLAY_NAME} = ?",
            arrayOf("$relativo%", nome),
            null,
        )?.use { cursor ->
            if (cursor.moveToFirst()) {
                android.content.ContentUris.withAppendedId(colecao, cursor.getLong(0))
            } else {
                null
            }
        }

        val destino = existente ?: resolver.insert(
            colecao,
            ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, nome)
                put(MediaStore.Downloads.MIME_TYPE, "application/json")
                put(MediaStore.Downloads.RELATIVE_PATH, relativo)
            },
        ) ?: return null

        // "wt" trunca o que havia antes; sem isso sobra a cauda do arquivo
        // velho quando o novo é menor.
        resolver.openOutputStream(destino, "wt")?.use { it.write(bytes) } ?: return null
        return "$relativo/$nome"
    }

    @Suppress("DEPRECATION")
    private fun salvarDireto(nome: String, bytes: ByteArray): String? {
        val pasta = File(
            Environment.getExternalStoragePublicDirectory(
                Environment.DIRECTORY_DOWNLOADS,
            ),
            PASTA,
        )
        if (!pasta.exists() && !pasta.mkdirs()) return null
        val arquivo = File(pasta, nome)
        arquivo.writeBytes(bytes)
        return "${Environment.DIRECTORY_DOWNLOADS}/$PASTA/$nome"
    }
}
