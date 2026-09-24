import bcrypt from 'bcryptjs';
import crypto from 'crypto';
import jwt from 'jsonwebtoken';
import {
  ACCESS_SEGUNDOS,
  REFRESH_MS,
  REFRESH_SEGUNDOS,
  REFRESH_TOLERANCIA_SEGUNDOS,
  getJwtSecret,
  JWT_ALGORITHM,
  JWT_AUDIENCE,
  JWT_ISSUER,
} from '../../shared/config/jwt';
import { AppError } from '../../shared/errors';
import { logger } from '../../shared/http/logger';
import {
  enviarBoasVindas,
  enviarCodigoRecuperacao,
  envioDisponivel,
} from '../../shared/email/enviar_email';
import * as repo from './auth.repository';

export type Tokens = {
  token: string;
  refreshToken: string;
  expiresIn: number;
  email: string;
  id: number;
};

type JwtRefresh = { id?: unknown; typ?: unknown };

/**
 * E-mail inexistente também paga o bcrypt, senão o tempo de resposta
 * entrega quem tem conta. Gerado uma vez no boot.
 */
const HASH_FANTASMA = bcrypt.hashSync('sem-conta-neste-email', 10);

const criarTokens = (id: number, email: string): Tokens => {
  const secret = getJwtSecret();
  const opcoes = {
    algorithm: JWT_ALGORITHM,
    issuer: JWT_ISSUER,
    audience: JWT_AUDIENCE,
  };
  const token = jwt.sign({ id, typ: 'access' }, secret, {
    ...opcoes,
    expiresIn: ACCESS_SEGUNDOS,
  });
  const refreshToken = jwt.sign({ id, typ: 'refresh' }, secret, {
    ...opcoes,
    expiresIn: REFRESH_SEGUNDOS,
    jwtid: crypto.randomUUID(),
  });
  return { token, refreshToken, expiresIn: ACCESS_SEGUNDOS, email, id };
};

const emitir = async (id: number, email: string): Promise<Tokens> => {
  const tokens = criarTokens(id, email);
  await repo.gravarSessao(
    id,
    repo.hashRefresh(tokens.refreshToken),
    new Date(Date.now() + REFRESH_MS),
  );
  return tokens;
};

export const autenticar = async (
  email: string,
  senha: string,
): Promise<(Tokens & { termosVersao: string | null }) | null> => {
  const usuario = await repo.buscarPorEmail(email);
  const senhaValida = await bcrypt.compare(senha, usuario?.senha ?? HASH_FANTASMA);
  if (!usuario || !senhaValida) return null;

  if (!usuario.ativo) {
    throw new AppError(403, 'Conta desativada.');
  }

  // A versão dos termos aceita vai junto, para o app saber se precisa
  // mostrar o aceite antes de mandar a caderneta para a nuvem (ADR 0038).
  const tokens = await emitir(usuario.id, usuario.email);
  return { ...tokens, termosVersao: usuario.termos_versao ?? null };
};

export const registrar = async (
  email: string,
  senha: string,
  termosVersao: string | null = null,
): Promise<{ id: number; email: string }> => {
  const existente = await repo.buscarPorEmail(email);
  if (existente) {
    throw new AppError(409, 'E-mail já cadastrado.');
  }
  const senhaCriptografada = await bcrypt.hash(senha, 10);
  const usuario = await repo.salvar(email, senhaCriptografada, termosVersao);

  // Não espera o Resend: a conta já existe, e e-mail que falha não pode
  // desfazer nem atrasar o cadastro (ADR 0036).
  void enviarBoasVindas({ para: usuario.email, usuarioId: usuario.id })
    .catch((erro) => {
      logger.error('Falha ao enviar boas-vindas', {
        usuarioId: usuario.id,
        detalhe: erro instanceof Error ? erro.message : 'erro',
      });
    });

  return usuario;
};

export const renovar = async (refreshToken: string): Promise<Tokens> => {
  let decoded: JwtRefresh;
  try {
    decoded = jwt.verify(refreshToken, getJwtSecret(), {
      algorithms: [JWT_ALGORITHM],
      issuer: JWT_ISSUER,
      audience: JWT_AUDIENCE,
    }) as JwtRefresh;
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

  const usuario = await repo.buscarPorId(id);
  if (!usuario || !usuario.ativo) {
    throw new AppError(401, 'Token inválido ou expirado.');
  }

  const tokens = criarTokens(usuario.id, usuario.email);
  const resultado = await repo.rotacionarSessao(
    repo.hashRefresh(refreshToken),
    usuario.id,
    repo.hashRefresh(tokens.refreshToken),
    new Date(Date.now() + REFRESH_MS),
    REFRESH_TOLERANCIA_SEGUNDOS,
  );
  if (resultado === 'reutilizada') {
    await repo.revogarTodas(usuario.id);
  }
  if (resultado !== 'ok') {
    throw new AppError(401, 'Token inválido ou expirado.');
  }
  return tokens;
};

/** Sai só deste aparelho: revoga o refresh enviado. Os outros seguem. */
export const sair = async (refreshToken?: string): Promise<void> => {
  if (!refreshToken) return;
  const sessao = await repo.buscarSessao(repo.hashRefresh(refreshToken));
  if (sessao) await repo.revogarSessao(sessao.id);
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

// Recuperação de senha por código enviado ao e-mail.

const CODIGO_MS = 15 * 60 * 1000;
const CODIGOS_POR_HORA = 3;
const TENTATIVAS_POR_CODIGO = 5;
const ERRO_CODIGO = 'Código inválido ou vencido.';

const gerarCodigo = (): string =>
  String(crypto.randomInt(0, 1_000_000)).padStart(6, '0');

/** HMAC com o segredo do JWT: quem lê o banco não recupera o código. */
const hashCodigo = (codigo: string): string =>
  crypto.createHmac('sha256', getJwtSecret()).update(codigo).digest('hex');

const codigoConfere = (codigo: string, hashGuardado: string): boolean => {
  const a = Buffer.from(hashCodigo(codigo), 'hex');
  const b = Buffer.from(hashGuardado, 'hex');
  return a.length === b.length && crypto.timingSafeEqual(a, b);
};

/**
 * Responde igual com ou sem conta. O envio não é aguardado, para o tempo
 * de resposta não denunciar quem tem cadastro.
 */
export const recuperarSenha = async (email: string): Promise<void> => {
  if (!envioDisponivel()) {
    throw new AppError(503, 'Recuperação de senha não está ligada neste servidor.');
  }
  const usuario = await repo.buscarPorEmail(email);
  if (!usuario || !usuario.ativo) return;

  // A contagem por hora fica dentro da transação, senão pedidos simultâneos
  // leem o mesmo total e todos passam.
  const codigo = gerarCodigo();
  const resultado = await repo.criarCodigoRecuperacao(
    usuario.id,
    hashCodigo(codigo),
    new Date(Date.now() + CODIGO_MS),
    CODIGOS_POR_HORA,
  );
  if (resultado === 'limite') {
    throw new AppError(429, 'Já foram pedidos 3 códigos na última hora. Aguarde para pedir outro.');
  }
  if (resultado !== 'criado') return;

  void enviarCodigoRecuperacao({ para: usuario.email, usuarioId: usuario.id, codigo })
    .catch((erro) => {
      logger.error('Falha ao enviar código de recuperação', {
        usuarioId: usuario.id,
        detalhe: erro instanceof Error ? erro.message : 'erro',
      });
    });
};

/**
 * Um só erro para toda falha, para não dizer qual parte errou. Devolve a
 * versão dos termos como o login, porque redefinir também entra na conta,
 * muitas vezes num celular novo (ADR 0038).
 */
export const redefinirSenha = async (
  email: string,
  codigo: string,
  senhaNova: string,
): Promise<Tokens & { termosVersao: string | null }> => {
  const usuario = await repo.buscarPorEmail(email);
  if (!usuario || !usuario.ativo) {
    throw new AppError(401, ERRO_CODIGO);
  }
  const ativo = await repo.buscarCodigoAtivo(usuario.id);
  if (!ativo) {
    throw new AppError(401, ERRO_CODIGO);
  }
  const temTentativa = await repo.consumirTentativa(ativo.id, TENTATIVAS_POR_CODIGO);
  if (!temTentativa || !codigoConfere(codigo, ativo.codigo_hash)) {
    throw new AppError(401, ERRO_CODIGO);
  }
  const marcado = await repo.marcarCodigoUsado(ativo.id);
  if (!marcado) {
    throw new AppError(401, ERRO_CODIGO);
  }

  const senhaCriptografada = await bcrypt.hash(senhaNova, 10);
  await repo.atualizarSenha(usuario.id, senhaCriptografada);
  await repo.revogarTodas(usuario.id);
  const tokens = await emitir(usuario.id, usuario.email);
  return { ...tokens, termosVersao: usuario.termos_versao ?? null };
};

/** Quem já tem conta aceita a versão nova dos termos (ADR 0038). */
export const aceitarTermos = async (
  usuarioId: number,
  versao: string,
): Promise<{ termosVersao: string }> => {
  const existia = await repo.registrarAceiteTermos(usuarioId, versao);
  if (!existia) throw new AppError(404, 'Conta não encontrada.');
  return { termosVersao: versao };
};
