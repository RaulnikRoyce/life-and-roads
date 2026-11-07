-- Linhas antigas usam o timestamp como versao ate a primeira gravacao.
ALTER TABLE fichas ADD COLUMN atualizado_em_ms BIGINT UNSIGNED NULL;
