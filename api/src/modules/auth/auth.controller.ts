import { asyncHandler, AppError } from '../../shared/errors';
import { criado, ok } from '../../shared/http/resposta';
import * as authService from './auth.service';

export const login = asyncHandler(async (req, res) => {
  const { email, senha } = req.body as { email: string; senha: string };
  const tokens = await authService.autenticar(email, senha);
  if (!tokens) {
    throw new AppError(401, 'Credenciais inválidas');
  }
  res.json({
    mensagem: 'Login realizado',
    ...tokens,
  });
});

export const registrar = asyncHandler(async (req, res) => {
  const { email, senha } = req.body as { email: string; senha: string };
  await authService.registrar(email, senha);
  criado(res, 'Conta criada');
});

export const refresh = asyncHandler(async (req, res) => {
  const { refreshToken } = req.body as { refreshToken: string };
  const tokens = await authService.renovar(refreshToken);
  res.json({
    mensagem: 'Sessão renovada',
    ...tokens,
  });
});

export const sair = asyncHandler(async (req, res) => {
  const { refreshToken } = (req.body || {}) as { refreshToken?: string };
  await authService.sair(req.usuario?.id ?? null, refreshToken);
  ok(res, { mensagem: 'Sessão encerrada' });
});

export const excluirConta = asyncHandler(async (req, res) => {
  const id = req.usuario?.id;
  if (!id) throw new AppError(401, 'Token não fornecido.');
  await authService.excluirConta(id);
  ok(res, { mensagem: 'Conta excluída' });
});

export const senha = asyncHandler(async (req, res) => {
  const id = req.usuario?.id;
  if (!id) throw new AppError(401, 'Token não fornecido.');
  const { senhaAtual, senhaNova } = req.body as {
    senhaAtual: string;
    senhaNova: string;
  };
  const tokens = await authService.trocarSenha(id, senhaAtual, senhaNova);
  res.json({
    mensagem: 'Senha alterada',
    ...tokens,
  });
});
