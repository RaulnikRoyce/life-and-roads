CREATE TABLE IF NOT EXISTS fichas (
  id INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id INT NOT NULL UNIQUE,
  marca VARCHAR(40) NOT NULL,
  modelo VARCHAR(60) NOT NULL,
  ano SMALLINT NULL,
  cilindrada SMALLINT NULL,
  km_litro DECIMAL(5,2) NOT NULL,
  km_litro_alcool DECIMAL(5,2) NULL,
  combustivel VARCHAR(10) NOT NULL DEFAULT 'gasolina',
  km_atual DECIMAL(10,1) NOT NULL,
  tanque_litros DECIMAL(4,1) NULL,
  personalizacoes VARCHAR(200) NULL,
  atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_ficha_usuario
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
);
