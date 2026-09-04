-- Caderneta remota do life.and.roads.
-- Uma ficha, uma manutenção e um ponto por usuário.
-- Sem placa, chassi, RENAVAM, foto ou histórico de rastro.

CREATE DATABASE IF NOT EXISTS life_and_roads
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE life_and_roads;

-- Grant minimal privileges to the application user (created by MYSQL_USER/MYSQL_PASSWORD).
-- The application needs SELECT, INSERT, UPDATE, DELETE on all tables, but not DDL privileges.
-- Note: MYSQL_USER is automatically created by the MySQL Docker image with access to MYSQL_DATABASE.
-- This ensures the application user has only the necessary privileges and cannot modify schema.

CREATE TABLE IF NOT EXISTS usuarios (
  id INT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(255) NOT NULL UNIQUE,
  senha VARCHAR(255) NOT NULL,
  ativo TINYINT(1) NOT NULL DEFAULT 1,
  criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Uma ficha por piloto. Sem placa, chassi ou RENAVAM.
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
  -- Autonomia = tanque × km/l. NULL = ainda não informado.
  tanque_litros DECIMAL(4,1) NULL,
  personalizacoes VARCHAR(200) NULL,
  atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_ficha_usuario
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
);

-- Óleo e pneus têm próxima data (lembrete). Revisão geral: só a última.
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

-- Só o último ponto. Sem rastro, sem cerca virtual.
CREATE TABLE IF NOT EXISTS localizacoes (
  usuario_id INT NOT NULL PRIMARY KEY,
  latitude DECIMAL(9,6) NOT NULL,
  longitude DECIMAL(9,6) NOT NULL,
  atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_local_usuario
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
);

-- Refresh tokens revogáveis. Access JWT continua curto e sem rastro.
CREATE TABLE IF NOT EXISTS sessoes (
  id INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id INT NOT NULL,
  token_hash CHAR(64) NOT NULL UNIQUE,
  expira_em DATETIME NOT NULL,
  revogada TINYINT(1) NOT NULL DEFAULT 0,
  criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_sessao_usuario
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
  INDEX idx_sessoes_usuario (usuario_id)
);
