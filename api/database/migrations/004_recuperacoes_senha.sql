CREATE TABLE IF NOT EXISTS recuperacoes_senha (
  id INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id INT NOT NULL,
  codigo_hash CHAR(64) NOT NULL,
  expira_em DATETIME NOT NULL,
  tentativas TINYINT NOT NULL DEFAULT 0,
  usada_em DATETIME NULL,
  criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_recuperacao_usuario
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
  INDEX idx_recuperacoes_usuario (usuario_id),
  INDEX idx_recuperacoes_expira (expira_em)
);
