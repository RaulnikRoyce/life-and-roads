/**
 * E-mail de boas-vindas, mandado uma vez quando o piloto cria a conta.
 *
 * Responde de saída as três perguntas de quem acabou de se cadastrar. O
 * que a conta guarda, o que continua só no celular, e como voltar se
 * esquecer a senha. Termina convidando a responder, agora que o endereço
 * de envio recebe e-mail (ADR 0036), inclusive para quem recebeu sem ter
 * pedido e quer a conta apagada. Não leva nada do piloto, nem o e-mail.
 */

import { FERRUGEM, CREME, MUTE, OSWALD, TEXTO, TINTA, fio, molduraHtml, traco } from './moldura';

const GUARDA =
  'A partir de agora, a ficha da sua moto e as datas de manutenção ficam guardadas na sua conta e voltam quando você entrar em outro celular.';
const FICA_NO_CELULAR =
  'Abastecimentos, fotos e os pontos marcados no mapa continuam só no seu celular. Para levar tudo numa troca de aparelho, use o botão Enviar backup, na aba Ficha.';
const SENHA =
  'Esqueceu a senha? Na aba Ficha, abra Conta e toque em Esqueci a senha. Um código chega neste e-mail.';
const RESPONDA = 'Dúvida, sugestão ou algo que não funcionou, responda este e-mail.';
const NAO_FOI_VOCE = 'Se não foi você quem criou esta conta, responda também e ela é apagada.';

export const textoDasBoasVindas = (): string => [
  'Sua conta no life.and.roads está pronta.',
  '',
  GUARDA,
  '',
  FICA_NO_CELULAR,
  '',
  SENHA,
  '',
  RESPONDA,
  NAO_FOI_VOCE,
].join('\n');

const paragrafo = (texto: string, topo: number): string =>
  `<p style="margin:${topo}px 0 0 0;font-family:${TEXTO};font-size:16px;line-height:25px;color:${TINTA};">${texto}</p>`;

export const htmlDasBoasVindas = (): string =>
  molduraHtml({
    titulo: 'Sua conta no life.and.roads está pronta',
    previa: 'A ficha e as datas de manutenção agora voltam se você trocar de celular.',
    corpo: `<tr><td align="center" style="padding:56px 16px 0 16px;">
  <p style="margin:0;font-family:${OSWALD};font-size:13px;line-height:18px;letter-spacing:3.5px;text-transform:uppercase;font-weight:500;color:${FERRUGEM};">Conta criada</p>
  <p style="margin:14px 0 0 0;font-family:${OSWALD};font-size:30px;line-height:36px;letter-spacing:1px;font-weight:600;color:${CREME};">Sua conta está pronta</p>
  ${traco()}
  <p style="margin:24px 0 0 0;font-family:${TEXTO};font-size:17px;line-height:26px;color:${TINTA};">${GUARDA}</p>
</td></tr>

<tr><td align="left" style="padding:40px 16px 0 16px;">
  ${paragrafo(FICA_NO_CELULAR, 0)}
  ${paragrafo(SENHA, 18)}
</td></tr>

<tr><td align="center" style="padding:48px 16px 0 16px;">
  ${fio()}
  <p style="margin:22px 0 0 0;font-family:${TEXTO};font-size:14px;line-height:22px;color:${MUTE};">${RESPONDA}<br>${NAO_FOI_VOCE}</p>
</td></tr>`,
  });
