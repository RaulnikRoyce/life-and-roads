import { logger } from '../http/logger';
import { htmlDoCodigo, textoDoCodigo } from './modelo_codigo';

export type Mensagem = {
  para: string;
  assunto: string;
  texto: string;
  /** Versão formatada; o texto puro segue como alternativa. */
  html?: string;
};

export type Transporte = (mensagem: Mensagem) => Promise<void>;

const REMETENTE_PADRAO = 'life.and.roads <no-reply@raulnikroyce.dev>';
const RESEND_URL = 'https://api.resend.com/emails';

let transporteInjetado: Transporte | null = null;

/** Testes injetam um transporte falso e capturam a mensagem. `null` volta ao padrão. */
export const usarTransporte = (transporte: Transporte | null): void => {
  transporteInjetado = transporte;
};

const emProducao = (): boolean => process.env.NODE_ENV === 'production';

/**
 * Em produção só envia com RESEND_API_KEY (ou transporte injetado).
 * Fora dela o código vai para o log, então o fluxo funciona sem chave.
 */
export const envioDisponivel = (): boolean =>
  transporteInjetado !== null || Boolean(process.env.RESEND_API_KEY) || !emProducao();

const enviarPeloResend = async (chave: string, mensagem: Mensagem): Promise<void> => {
  const resposta = await fetch(RESEND_URL, {
    method: 'POST',
    headers: {
      authorization: `Bearer ${chave}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      from: process.env.EMAIL_REMETENTE || REMETENTE_PADRAO,
      to: [mensagem.para],
      subject: mensagem.assunto,
      text: mensagem.texto,
      ...(mensagem.html ? { html: mensagem.html } : {}),
    }),
  });
  if (!resposta.ok) {
    throw new Error(`Resend respondeu ${resposta.status}`);
  }
};

/**
 * Envia o código de recuperação. Transporte injetado > Resend > log local.
 * Nunca registra o e-mail do piloto; o código só sai no log fora de produção.
 */
export const enviarCodigoRecuperacao = async (dados: {
  para: string;
  usuarioId: number;
  codigo: string;
}): Promise<void> => {
  const mensagem: Mensagem = {
    para: dados.para,
    assunto: 'Seu código para redefinir a senha',
    texto: textoDoCodigo(dados.codigo),
    html: htmlDoCodigo(dados.codigo),
  };

  if (transporteInjetado) {
    await transporteInjetado(mensagem);
    return;
  }

  const chave = process.env.RESEND_API_KEY;
  if (chave) {
    await enviarPeloResend(chave, mensagem);
    return;
  }

  if (emProducao()) {
    throw new Error('RESEND_API_KEY ausente em produção.');
  }
  logger.info('codigo_recuperacao', { usuarioId: dados.usuarioId, codigo: dados.codigo });
};
