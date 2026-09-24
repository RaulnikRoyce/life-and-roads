-- Caderneta na nuvem (ADR 0038): o que hoje só existe no aparelho, menos a
-- foto, cifrado com AES-256-GCM pela chave do servidor. O banco guarda só
-- bytes; sem a CADERNETA_CHAVE ninguém lê, nem o dump semanal.
--
-- atualizado_em_ms é o carimbo que decide o 409 do PUT, em milissegundos
-- inteiros para ser comparado exatamente, sem fuso nem arredondamento.
CREATE TABLE IF NOT EXISTS cadernetas_nuvem (
  usuario_id INT NOT NULL PRIMARY KEY,
  conteudo MEDIUMBLOB NOT NULL,
  versao_chave TINYINT UNSIGNED NOT NULL,
  tamanho INT UNSIGNED NOT NULL,
  atualizado_em_ms BIGINT UNSIGNED NOT NULL,
  CONSTRAINT fk_caderneta_nuvem_usuario
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
);
