const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');

const authRoutes = require('./routes/auth.routes');
const fichaRoutes = require('./routes/ficha.routes');
const manutencaoRoutes = require('./routes/manutencao.routes');
const localizacaoRoutes = require('./routes/localizacao.routes');
const { manipularErros, rotaNaoEncontrada } = require('./middlewares/erros');
const logger = require('./utils/logger');

const app = express();
const emProducao = process.env.NODE_ENV === 'production';

if (emProducao) {
    app.set('trust proxy', 1);
}

const allowedOrigins = process.env.CORS_ORIGIN
    ? process.env.CORS_ORIGIN.split(',').map((origin) => origin.trim()).filter(Boolean)
    : [];

app.use(helmet());

app.use(cors({
    origin: (origin, callback) => {
        if (!origin) return callback(null, true);
        const local = !emProducao && (
            origin.startsWith('http://localhost:') || origin.startsWith('http://127.0.0.1:')
        );
        if (local || allowedOrigins.includes(origin)) return callback(null, true);
        return callback(null, false);
    }
}));

app.use(express.json({ limit: '20kb' }));

app.use((req, res, next) => {
    if (req.path === '/health') return next();
    const inicio = Date.now();
    res.on('finish', () => {
        logger.info('http', {
            metodo: req.method,
            rota: req.originalUrl,
            status: res.statusCode,
            ms: Date.now() - inicio
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
    skip: (req) => req.path === '/health'
}));

app.get('/health', (_req, res) => res.json({ status: 'ok' }));

app.use('/auth', authRoutes);
app.use('/ficha', fichaRoutes);
app.use('/manutencao', manutencaoRoutes);
app.use('/localizacao', localizacaoRoutes);

app.get('/', (_req, res) => res.json({
    mensagem: 'API life.and.roads',
    health: '/health'
}));

app.use(rotaNaoEncontrada);
app.use(manipularErros);

module.exports = app;
