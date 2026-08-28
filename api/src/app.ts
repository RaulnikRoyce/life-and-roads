import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import fs from 'fs';
import path from 'path';
import authRoutes from './modules/auth/auth.routes';
import fichaRoutes from './modules/ficha/ficha.routes';
import manutencaoRoutes from './modules/manutencao/manutencao.routes';
import localizacaoRoutes from './modules/localizacao/localizacao.routes';
import monitorRoutes from './modules/monitor/monitor.routes';
import { manipularErros, rotaNaoEncontrada } from './shared/http/erros';
import { logger } from './shared/http/logger';
import { requestId } from './shared/http/request-id';
import { pingBanco } from './shared/database/pool';
import { appEnv } from './shared/config/ambiente';
import { metricas } from './shared/http/metricas';

const app = express();
const ambiente = appEnv();
const emProducao = process.env.NODE_ENV === 'production';

if (emProducao) {
  app.set('trust proxy', 1);
}

const allowedOrigins = process.env.CORS_ORIGIN
  ? process.env.CORS_ORIGIN.split(',').map((origin) => origin.trim()).filter(Boolean)
  : [];

app.use(helmet());
app.use(requestId);

app.use(cors({
  origin: (origin, callback) => {
    if (!origin) return callback(null, true);
    const local = !emProducao && (
      origin.startsWith('http://localhost:') || origin.startsWith('http://127.0.0.1:')
    );
    if (local || allowedOrigins.includes(origin)) return callback(null, true);
    return callback(null, false);
  },
}));

app.use(express.json({ limit: '20kb' }));

app.use((req, res, next) => {
  if (req.path === '/health' || req.path === '/ready') return next();
  metricas.toqueHttp();
  const inicio = Date.now();
  res.on('finish', () => {
    if (res.statusCode >= 500) metricas.toque5xx();
    logger.info('http', {
      metodo: req.method,
      rota: req.originalUrl,
      status: res.statusCode,
      ms: Date.now() - inicio,
      request_id: req.requestId,
      env: ambiente,
    });
  });
  next();
});

app.use(rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 300,
  standardHeaders: true,
  legacyHeaders: false,
  message: { erro: 'Muitas requisições. Tente novamente em alguns minutos.' },
  skip: (req) => req.path === '/health' || req.path === '/ready',
}));

app.get('/health', (_req, res) => res.json({
  status: 'ok',
  env: ambiente,
  ...metricas.resumo(),
}));

app.get('/ready', async (_req, res) => {
  try {
    await pingBanco();
    res.json({ status: 'ok', banco: true });
  } catch {
    res.status(503).json({ status: 'erro', banco: false });
  }
});

app.get('/openapi.yaml', (_req, res) => {
  const arquivo = path.join(process.cwd(), '..', 'docs', 'openapi.yaml');
  const local = path.join(process.cwd(), 'openapi.yaml');
  const alvo = fs.existsSync(arquivo) ? arquivo : local;
  if (!fs.existsSync(alvo)) {
    res.status(404).json({ erro: 'OpenAPI não encontrado' });
    return;
  }
  res.type('text/yaml').send(fs.readFileSync(alvo, 'utf8'));
});

app.use('/auth', authRoutes);
app.use('/ficha', fichaRoutes);
app.use('/manutencao', manutencaoRoutes);
app.use('/localizacao', localizacaoRoutes);
app.use('/monitor', monitorRoutes);

app.get('/', (_req, res) => res.json({
  mensagem: 'API life.and.roads',
  health: '/health',
  ready: '/ready',
  openapi: '/openapi.yaml',
}));

app.use(rotaNaoEncontrada);
app.use(manipularErros);

export default app;
