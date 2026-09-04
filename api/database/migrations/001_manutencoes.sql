CREATE TABLE IF NOT EXISTS manutencoes (
  id INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id INT NOT NULL UNIQUE,
  oleo_ultima DATE NULL,
  oleo_proxima DATE NULL,
  revisao_ultima DATE NULL,
  pneus_ultima DATE NULL,
  pneus_proxima DATE NULL,
  ipva_proxima DATE NULL,
  seguro_proxima DATE NULL,
  licenciamento_proxima DATE NULL,
  atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_manutencao_usuario
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
);
