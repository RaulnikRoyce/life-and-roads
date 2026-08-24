# life.and.roads

Caderneta de **uma moto**: ficha, manutenção, viagem e último ponto no mapa.

## Sobre este projeto

Este repositório faz parte de um **projeto pessoal**. O objetivo é treinar um produto real da minha atuação como **piloto** — motoclube, viagem a dois, estrada no fim de semana: km do painel, tanque, posto, óleo e o “cabe nesta bomba?”. O tipo de caderneta que uso na moto, não um feed de comunidade.

O life.and.roads nasceu **solo** na ideia, na estrutura e no modo de funcionar: as quatro abas, o recorte (sem placa, sem FIPE, mapa como **uma tela**) e o primeiro código foram definidos e escritos por mim. Com o auxílio do [Cursor](https://cursor.com) fizemos muitas alterações (catálogo, polimento e fechamento) para concluir o projeto — o Cursor é coautor neste projeto.

## Por que esta arquitetura

App de moto no Brasil costuma misturar comunidade, tabela e marketing. Este é o contrário: números do posto e da oficina, toque grande, pouca letra.

A caderneta inteira funciona **neste aparelho**, sem conta. Login é opcional (ficha + datas de manutenção + último ponto), para não sumir na troca de celular. A API não recebe placa, chassi, foto, PSI, pins nem backup: o schema é `.strict()` e campo extra é recusado. Uma ficha por piloto.

## Stack

Flutter (Android) · Dart · Node.js · Express · MySQL · JWT · Zod · flutter_map + OpenStreetMap (sem chave Google)

## Subir local

1. MySQL em `127.0.0.1:3306` e importe `api/database/schema.sql`
2. Copie `api/.env.example` para `api/.env` e preencha o banco + `JWT_SECRET`
3. Instale e suba a API:

```bash
cd api
npm install
npm test
node server.js
