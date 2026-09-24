/**
 * Corpo do e-mail com o código de recuperação, em texto puro e em HTML.
 *
 * O HTML é a tela de abertura do app em forma de e-mail: fundo asfalto do
 * começo ao fim, a logo grande, a marca em Oswald e o código em número
 * grande, com o mínimo em volta. Layout em tabelas com estilo inline, sem
 * rastreio e sem nenhum recurso de fora do domínio. A logo é servida pela
 * própria API em `/marca/logo.png`, e as fontes são só nomes com
 * alternativa do sistema, sem baixar nada.
 */

export const textoDoCodigo = (codigo: string): string => [
  `Seu código para redefinir a senha no life.and.roads é ${codigo}.`,
  '',
  'O código vale 15 minutos e serve uma única vez.',
  '',
  'Se não foi você quem pediu, ignore este e-mail. Sua senha continua a mesma.',
].join('\n');

/** Troca os cinco caracteres que abrem tag ou atributo. */
export const escaparHtml = (valor: string): string =>
  valor
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');

/** Base pública da API, de onde o cliente de e-mail busca a logo. */
export const urlPublica = (): string =>
  (process.env.API_URL_PUBLICA || 'https://api.raulnikroyce.dev').replace(/\/$/, '');

// Cores do tema escuro (app/lib/tema.dart).
const ASFALTO = '#121212';
const CREME = '#F5F5F5';
const TINTA = '#C8C8C8';
const MUTE = '#8A8A8A';
const APAGADO = '#5A5A5A';
const FIO = '#2A2A2A';
const LATAO = '#8B4545';
const FERRUGEM = '#A35555';

// Só nomes de fonte, sem baixar nada. Quem já tem Oswald instalada vê
// Oswald; o resto cai em Helvetica. Buscar do Google Fonts foi tirado
// porque o Gmail ignora fonte externa e ainda lê o link como recurso fora
// do domínio de envio, o que empurra para o spam.
const OSWALD = "'Oswald','Helvetica Neue',Helvetica,Arial,sans-serif";
const TEXTO = "'Source Sans 3','Segoe UI',Roboto,'Helvetica Neue',Arial,sans-serif";

const traco = (): string =>
  `<table role="presentation" cellpadding="0" cellspacing="0" border="0" align="center" style="margin:22px auto 0 auto;"><tr><td width="40" height="3" bgcolor="${LATAO}" style="width:40px;height:3px;line-height:3px;font-size:3px;background-color:${LATAO};border-radius:2px;">&nbsp;</td></tr></table>`;

export const htmlDoCodigo = (codigo: string): string => {
  const c = escaparHtml(codigo);
  const logo = `${urlPublica()}/marca/logo.png`;
  return `<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="x-apple-disable-message-reformat">
<meta name="color-scheme" content="dark">
<meta name="supported-color-schemes" content="dark">
<title>Seu código para redefinir a senha</title>
</head>
<body style="margin:0;padding:0;background-color:${ASFALTO};-webkit-text-size-adjust:100%;">
<div style="display:none;max-height:0;overflow:hidden;opacity:0;color:transparent;font-size:1px;line-height:1px;">Seu código é ${c}. Vale 15 minutos e serve uma única vez.&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;</div>

<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" bgcolor="${ASFALTO}" style="background-color:${ASFALTO};">
<tr><td align="center" style="padding:0 16px;">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="max-width:520px;">

<tr><td style="padding:0;"><table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0"><tr><td height="2" bgcolor="${LATAO}" style="height:2px;line-height:2px;font-size:2px;background-color:${LATAO};">&nbsp;</td></tr></table></td></tr>

<tr><td align="center" style="padding:56px 16px 0 16px;">
  <img src="${logo}" width="186" height="200" alt="life.and.roads" style="display:block;width:186px;height:200px;border:0;margin:0 auto;">
  <p style="margin:26px 0 0 0;font-family:${OSWALD};font-size:30px;line-height:34px;letter-spacing:3px;font-weight:600;color:${CREME};">life.and.roads</p>
  <p style="margin:8px 0 0 0;font-family:${OSWALD};font-size:12px;line-height:18px;letter-spacing:3px;text-transform:uppercase;font-weight:500;color:${MUTE};">Caderneta da sua moto</p>
</td></tr>

<tr><td align="center" style="padding:56px 16px 0 16px;">
  <p style="margin:0;font-family:${OSWALD};font-size:13px;line-height:18px;letter-spacing:3.5px;text-transform:uppercase;font-weight:500;color:${FERRUGEM};">Seu código</p>
  <p style="margin:14px 0 0 0;font-family:${OSWALD};font-size:72px;line-height:80px;letter-spacing:16px;font-weight:600;color:${CREME};padding-left:16px;">${c}</p>
  ${traco()}
  <p style="margin:24px 0 0 0;font-family:${TEXTO};font-size:17px;line-height:26px;color:${TINTA};">Digite no app para redefinir a senha.<br>Vale 15 minutos e serve uma única vez.</p>
</td></tr>

<tr><td align="center" style="padding:56px 16px 0 16px;">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0"><tr><td height="1" bgcolor="${FIO}" style="height:1px;line-height:1px;font-size:1px;background-color:${FIO};">&nbsp;</td></tr></table>
  <p style="margin:22px 0 0 0;font-family:${TEXTO};font-size:14px;line-height:22px;color:${MUTE};">Se não foi você quem pediu, ignore este e-mail.<br>Sua senha continua a mesma.</p>
</td></tr>

<tr><td align="center" style="padding:40px 16px 44px 16px;">
  <p style="margin:0;font-family:${OSWALD};font-size:11px;line-height:16px;letter-spacing:2.5px;text-transform:uppercase;font-weight:500;color:${APAGADO};">life.and.roads &nbsp;·&nbsp; e-mail automático</p>
</td></tr>

</table>
</td></tr>
</table>
</body>
</html>
`;
};
