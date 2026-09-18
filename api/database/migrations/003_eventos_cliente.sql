CREATE TABLE IF NOT EXISTS eventos_cliente (
  id INT AUTO_INCREMENT PRIMARY KEY,
  tipo VARCHAR(20) NOT NULL,
  mensagem VARCHAR(500) NOT NULL,
  ambiente VARCHAR(20) NULL,
  versao_app VARCHAR(40) NULL,
  plataforma VARCHAR(80) NULL,
  pilha VARCHAR(2000) NULL,
  criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_eventos_cliente_criado (criado_em)
);
