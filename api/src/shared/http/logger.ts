const log = (
  nivel: 'info' | 'error',
  mensagem: string,
  extra: Record<string, unknown> = {},
): void => {
  const linha = JSON.stringify({
    nivel,
    mensagem,
    em: new Date().toISOString(),
    ...extra,
  });
  if (nivel === 'error') {
    console.error(linha);
    return;
  }
  console.log(linha);
};

export const logger = {
  info: (mensagem: string, extra?: Record<string, unknown>) =>
    log('info', mensagem, extra),
  error: (mensagem: string, extra?: Record<string, unknown>) =>
    log('error', mensagem, extra),
};
