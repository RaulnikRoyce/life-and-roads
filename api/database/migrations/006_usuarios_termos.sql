-- Aceite dos Termos de uso e da Privacidade (ADR 0038). A versão é a data do
-- texto aceito; nula para quem cadastrou antes ou por um app que ainda não
-- manda o campo.
ALTER TABLE usuarios
  ADD COLUMN termos_versao VARCHAR(10) NULL,
  ADD COLUMN termos_aceitos_em DATETIME NULL;
