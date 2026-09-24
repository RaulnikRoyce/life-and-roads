/**
 * Corpo do e-mail com o código de recuperação, em texto puro e em HTML.
 *
 * O miolo é o código em número grande, com o mínimo em volta. A moldura,
 * com fundo, logo, marca e rodapé, vem de `moldura.ts`, a mesma da
 * boas-vindas.
 */

import {
  CREME,
  FERRUGEM,
  MUTE,
  OSWALD,
  TEXTO,
  TINTA,
  escaparHtml,
  fio,
  molduraHtml,
  traco,
} from './moldura';

// Os testes e quem já importava daqui continuam achando estes dois aqui.
export { escaparHtml, urlPublica } from './moldura';

export const textoDoCodigo = (codigo: string): string => [
  `Seu código para redefinir a senha no life.and.roads é ${codigo}.`,
  '',
  'O código vale 15 minutos e serve uma única vez.',
  '',
  'Se não foi você quem pediu, ignore este e-mail. Sua senha continua a mesma.',
].join('\n');

export const htmlDoCodigo = (codigo: string): string => {
  const c = escaparHtml(codigo);
  return molduraHtml({
    titulo: 'Seu código para redefinir a senha',
    previa: `Seu código é ${codigo}. Vale 15 minutos e serve uma única vez.`,
    corpo: `<tr><td align="center" style="padding:56px 16px 0 16px;">
  <p style="margin:0;font-family:${OSWALD};font-size:13px;line-height:18px;letter-spacing:3.5px;text-transform:uppercase;font-weight:500;color:${FERRUGEM};">Seu código</p>
  <p style="margin:14px 0 0 0;font-family:${OSWALD};font-size:72px;line-height:80px;letter-spacing:16px;font-weight:600;color:${CREME};padding-left:16px;">${c}</p>
  ${traco()}
  <p style="margin:24px 0 0 0;font-family:${TEXTO};font-size:17px;line-height:26px;color:${TINTA};">Digite no app para redefinir a senha.<br>Vale 15 minutos e serve uma única vez.</p>
</td></tr>

<tr><td align="center" style="padding:56px 16px 0 16px;">
  ${fio()}
  <p style="margin:22px 0 0 0;font-family:${TEXTO};font-size:14px;line-height:22px;color:${MUTE};">Se não foi você quem pediu, ignore este e-mail.<br>Sua senha continua a mesma.</p>
</td></tr>`,
  });
};
