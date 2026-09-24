import { createCipheriv, createDecipheriv, randomBytes } from 'crypto';

/**
 * Cifra da caderneta na nuvem (ADR 0038).
 *
 * AES-256-GCM com a chave do env CADERNETA_CHAVE. Cada gravação sorteia um
 * IV novo, e o resultado vai para o banco como `iv | tag | cifrado`. O GCM
 * autentica o conteúdo, então um byte trocado no banco faz a abertura falhar
 * em vez de devolver lixo.
 *
 * O número da conta entra como dado autenticado. A cifra de um piloto copiada
 * para a linha de outro não abre, mesmo com a chave certa.
 */

const ALGORITMO = 'aes-256-gcm';
const TAMANHO_IV = 12;
const TAMANHO_TAG = 16;

/** Sobe quando a chave for trocada; cada linha guarda com qual foi cifrada. */
export const VERSAO_CHAVE_ATUAL = 1;

const BASE64_DE_32_BYTES = /^[A-Za-z0-9+/]{43}=$/;

/**
 * A chave do ambiente, ou null quando não foi configurada. Chave presente
 * mas malformada é erro de configuração e lança, para não cifrar com lixo.
 */
export const chaveDaCaderneta = (): Buffer | null => {
  const bruta = process.env.CADERNETA_CHAVE?.trim();
  if (!bruta) return null;
  if (!BASE64_DE_32_BYTES.test(bruta)) {
    throw new Error('CADERNETA_CHAVE precisa ser 32 bytes em base64 (openssl rand -base64 32).');
  }
  return Buffer.from(bruta, 'base64');
};

const dadoAutenticado = (usuarioId: number): Buffer =>
  Buffer.from(`caderneta:${usuarioId}`, 'utf8');

export const cifrar = (texto: string, chave: Buffer, usuarioId: number): Buffer => {
  const iv = randomBytes(TAMANHO_IV);
  const cifra = createCipheriv(ALGORITMO, chave, iv);
  cifra.setAAD(dadoAutenticado(usuarioId));
  const corpo = Buffer.concat([cifra.update(texto, 'utf8'), cifra.final()]);
  return Buffer.concat([iv, cifra.getAuthTag(), corpo]);
};

/** Lança se a chave for outra, se o conteúdo foi mexido ou se é de outra conta. */
export const decifrar = (dado: Buffer, chave: Buffer, usuarioId: number): string => {
  if (dado.length < TAMANHO_IV + TAMANHO_TAG) {
    throw new Error('Caderneta cifrada curta demais.');
  }
  const iv = dado.subarray(0, TAMANHO_IV);
  const tag = dado.subarray(TAMANHO_IV, TAMANHO_IV + TAMANHO_TAG);
  const corpo = dado.subarray(TAMANHO_IV + TAMANHO_TAG);
  const decifra = createDecipheriv(ALGORITMO, chave, iv);
  decifra.setAAD(dadoAutenticado(usuarioId));
  decifra.setAuthTag(tag);
  return Buffer.concat([decifra.update(corpo), decifra.final()]).toString('utf8');
};
