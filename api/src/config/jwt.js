const getJwtSecret = () => {
    const secret = process.env.JWT_SECRET;
    if (!secret) {
        throw new Error('JWT_SECRET não configurado.');
    }
    return secret;
};

module.exports = { getJwtSecret };
