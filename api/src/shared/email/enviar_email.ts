import { logger } from '../http/logger';
import { htmlDasBoasVindas, textoDasBoasVindas } from './modelo_boas_vindas';
import { htmlDoCodigo, textoDoCodigo } from './modelo_codigo';

/** Assunto de cada e-mail. Os testes separam um do outro por aqui. */
export const ASSUNTO_CODIGO = 'Seu código para redefinir a senha';
export const ASSUNTO_BOAS_VINDAS = 'Sua conta no life.and.roads está pronta';

export type Mensagem = {
  para: string;
  assunto: string;
  texto: string;
  /** Versão formatada; o texto puro segue como alternativa. */
  html?: string;
};

export type Transporte = (mensagem: Mensagem) => Promise<void>;

// O endereço recebe resposta desde 24/09/2026, pelo Email Routing do
// Cloudflare, que encaminha para o Raulnik (ADR 0036). Em produção vale o
// EMAIL_REMETENTE do Render; este padrão precisa ficar igual a ele.
const REMETENTE_PADRAO = 'life.and.roads <contato@raulnikroyce.dev>';
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
 * Caminho comum de todo e-mail. Transporte injetado > Resend > log local.
 * Sem chave fora de produção, `semChave` registra no log o que importa
 * para quem está desenvolvendo, e nunca o e-mail do piloto.
 */
const entregar = async (mensagem: Mensagem, semChave: () => void): Promise<void> => {
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
  semChave();
};

/** Envia o código de recuperação. O código só sai no log fora de produção. */
export const enviarCodigoRecuperacao = async (dados: {
  para: string;
  usuarioId: number;
  codigo: string;
}): Promise<void> =>
  entregar(
    {
      para: dados.para,
      assunto: ASSUNTO_CODIGO,
      texto: textoDoCodigo(dados.codigo),
      html: htmlDoCodigo(dados.codigo),
    },
    () => logger.info('codigo_recuperacao', { usuarioId: dados.usuarioId, codigo: dados.codigo }),
  );

/** Envia a boas-vindas, uma vez, logo depois de criar a conta. */
export const enviarBoasVindas = async (dados: {
  para: string;
  usuarioId: number;
}): Promise<void> =>
  entregar(
    {
      para: dados.para,
      assunto: ASSUNTO_BOAS_VINDAS,
      texto: textoDasBoasVindas(),
      html: htmlDasBoasVindas(),
    },
    () => logger.info('boas_vindas', { usuarioId: dados.usuarioId }),
  );
