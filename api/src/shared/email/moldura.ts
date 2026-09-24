/**
 * A moldura que todo e-mail do app usa: fundo asfalto do começo ao fim, a
 * faixa de latão no topo, a logo grande, a marca e o rodapé. Cada modelo
 * só escreve o miolo.
 *
 * Layout em tabelas com estilo inline, sem rastreio e sem nenhum recurso de
 * fora do domínio. A logo é servida pela própria API em `/marca/logo.png`,
 * e as fontes são só nomes com alternativa do sistema, sem baixar nada.
 */

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
export const ASFALTO = '#121212';
export const CREME = '#F5F5F5';
export const TINTA = '#C8C8C8';
export const MUTE = '#8A8A8A';
export const APAGADO = '#5A5A5A';
export const FIO = '#2A2A2A';
export const LATAO = '#8B4545';
export const FERRUGEM = '#A35555';

// Só nomes de fonte, sem baixar nada. Quem já tem Oswald instalada vê
// Oswald; o resto cai em Helvetica. Buscar do Google Fonts foi tirado
// porque o Gmail ignora fonte externa e ainda lê o link como recurso fora
// do domínio de envio, o que empurra para o spam.
export const OSWALD = "'Oswald','Helvetica Neue',Helvetica,Arial,sans-serif";
export const TEXTO = "'Source Sans 3','Segoe UI',Roboto,'Helvetica Neue',Arial,sans-serif";

/** O traço curto de latão que separa o título do texto. */
export const traco = (): string =>
  `<table role="presentation" cellpadding="0" cellspacing="0" border="0" align="center" style="margin:22px auto 0 auto;"><tr><td width="40" height="3" bgcolor="${LATAO}" style="width:40px;height:3px;line-height:3px;font-size:3px;background-color:${LATAO};border-radius:2px;">&nbsp;</td></tr></table>`;

/** A linha fina de largura inteira que abre a parte de rodapé do miolo. */
export const fio = (): string =>
  `<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0"><tr><td height="1" bgcolor="${FIO}" style="height:1px;line-height:1px;font-size:1px;background-color:${FIO};">&nbsp;</td></tr></table>`;

/**
 * Monta o e-mail inteiro em volta do miolo.
 *
 * `titulo` e `previa` chegam como texto e são escapados aqui; `corpo` já
 * chega como HTML, montado e escapado pelo modelo que chamou.
 */
export const molduraHtml = (m: { titulo: string; previa: string; corpo: string }): string => {
  const logo = `${urlPublica()}/marca/logo.png`;
  return `<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="x-apple-disable-message-reformat">
<meta name="color-scheme" content="dark">
<meta name="supported-color-schemes" content="dark">
<title>${escaparHtml(m.titulo)}</title>
</head>
<body style="margin:0;padding:0;background-color:${ASFALTO};-webkit-text-size-adjust:100%;">
<div style="display:none;max-height:0;overflow:hidden;opacity:0;color:transparent;font-size:1px;line-height:1px;">${escaparHtml(m.previa)}&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;</div>

<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" bgcolor="${ASFALTO}" style="background-color:${ASFALTO};">
<tr><td align="center" style="padding:0 16px;">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="max-width:520px;">

<tr><td style="padding:0;"><table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0"><tr><td height="2" bgcolor="${LATAO}" style="height:2px;line-height:2px;font-size:2px;background-color:${LATAO};">&nbsp;</td></tr></table></td></tr>

<tr><td align="center" style="padding:56px 16px 0 16px;">
  <img src="${logo}" width="186" height="200" alt="life.and.roads" style="display:block;width:186px;height:200px;border:0;margin:0 auto;">
  <p style="margin:26px 0 0 0;font-family:${OSWALD};font-size:30px;line-height:34px;letter-spacing:3px;font-weight:600;color:${CREME};">life.and.roads</p>
  <p style="margin:8px 0 0 0;font-family:${OSWALD};font-size:12px;line-height:18px;letter-spacing:3px;text-transform:uppercase;font-weight:500;color:${MUTE};">Caderneta da sua moto</p>
</td></tr>

${m.corpo}

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
