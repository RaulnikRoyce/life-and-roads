const jwt = require('jsonwebtoken');
const { getJwtSecret } = require('../config/jwt');

exports.verificarToken = (req, res, next) => {
    const authorization = req.get('authorization');

    if (!authorization || !authorization.startsWith('Bearer ')) {
        return res.status(401).json({ erro: 'Token não fornecido.' });
    }

    const token = authorization.slice(7).trim();
    if (!token) {
        return res.status(401).json({ erro: 'Token não fornecido.' });
    }

    try {
        const decoded = jwt.verify(token, getJwtSecret());
        const id = Number(decoded.id);
        if (!Number.isInteger(id) || id <= 0) {
            return res.status(401).json({ erro: 'Token inválido ou expirado.' });
        }
        req.usuario = { id };
        return next();
    } catch {
        return res.status(401).json({ erro: 'Token inválido ou expirado.' });
    }
};
