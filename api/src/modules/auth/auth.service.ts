import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import {
  ACCESS_SEGUNDOS,
  REFRESH_MS,
  REFRESH_SEGUNDOS,
  getJwtSecret,
} from '../../shared/config/jwt';
import { AppError } from '../../shared/errors';
import * as repo from './auth.repository';

export type Tokens = {
  token: string;
  refreshToken: string;
  expiresIn: number;
  email: string;
  id: number;
};

type JwtRefresh = { id?: unknown; typ?: unknown };

const emitir = async (id: number, email: string): Promise<Tokens> => {
  const secret = getJwtSecret();
  const token = jwt.sign({ id, typ: 'access' }, secret, { expiresIn: ACCESS_SEGUNDOS });
  const refreshToken = jwt.sign({ id, typ: 'refresh' }, secret, {
    expiresIn: REFRESH_SEGUNDOS,
  });
  await repo.gravarSessao(
    id,
    repo.hashRefresh(refreshToken),
    new Date(Date.now() + REFRESH_MS),
  );
  return { token, refreshToken, expiresIn: ACCESS_SEGUNDOS, email, id };
};

export const autenticar = async (
  email: string,
  senha: string,
): Promise<Tokens | null> => {
  const usuario = await repo.buscarPorEmail(email);
  if (!usuario) return null;

  const senhaValida = await bcrypt.compare(senha, usuario.senha);
  if (!senhaValida) return null;

  if (!usuario.ativo) {
    throw new AppError(403, 'Conta desativada.');
  }

  return emitir(usuario.id, usuario.email);
};

export const registrar = async (
  email: string,
  senha: string,
): Promise<{ id: number; email: string }> => {
  const existente = await repo.buscarPorEmail(email);
  if (existente) {
    throw new AppError(409, 'E-mail já cadastrado.');
  }
  const senhaCriptografada = await bcrypt.hash(senha, 10);
  return repo.salvar(email, senhaCriptografada);
};

export const renovar = async (refreshToken: string): Promise<Tokens> => {
  let decoded: JwtRefresh;
  try {
    decoded = jwt.verify(refreshToken, getJwtSecret()) as JwtRefresh;
  } catch {
    throw new AppError(401, 'Token inválido ou expirado.');
  }
  if (decoded.typ !== 'refresh') {
    throw new AppError(401, 'Token inválido ou expirado.');
  }
  const id = Number(decoded.id);
  if (!Number.isInteger(id) || id <= 0) {
    throw new AppError(401, 'Token inválido ou expirado.');
  }

  const hash = repo.hashRefresh(refreshToken);
  const sessao = await repo.buscarSessao(hash);
  if (!sessao || Number(sessao.revogada) === 1) {
    if (sessao) await repo.revogarTodas(sessao.usuario_id);
    throw new AppError(401, 'Token inválido ou expirado.');
  }
  if (new Date(sessao.expira_em).getTime() <= Date.now()) {
    await repo.revogarSessao(sessao.id);
    throw new AppError(401, 'Token inválido ou expirado.');
  }

  const usuario = await repo.buscarPorId(id);
  if (!usuario || !usuario.ativo) {
    throw new AppError(401, 'Token inválido ou expirado.');
  }

  await repo.revogarSessao(sessao.id);
  return emitir(usuario.id, usuario.email);
};

export const sair = async (
  usuarioId: number | null,
  refreshToken?: string,
): Promise<void> => {
  if (refreshToken) {
    const sessao = await repo.buscarSessao(repo.hashRefresh(refreshToken));
    if (sessao) await repo.revogarSessao(sessao.id);
  }
  if (usuarioId) await repo.revogarTodas(usuarioId);
};

export const excluirConta = async (usuarioId: number): Promise<void> => {
  await repo.revogarTodas(usuarioId);
  await repo.apagarUsuario(usuarioId);
};

export const trocarSenha = async (
  usuarioId: number,
  senhaAtual: string,
  senhaNova: string,
): Promise<Tokens> => {
  const usuario = await repo.buscarPorId(usuarioId);
  if (!usuario) {
    throw new AppError(401, 'Token inválido ou expirado.');
  }
  const senhaValida = await bcrypt.compare(senhaAtual, usuario.senha);
  if (!senhaValida) {
    throw new AppError(401, 'Senha atual incorreta.');
  }
  const senhaCriptografada = await bcrypt.hash(senhaNova, 10);
  await repo.atualizarSenha(usuario.id, senhaCriptografada);
  await repo.revogarTodas(usuario.id);
  return emitir(usuario.id, usuario.email);
};
