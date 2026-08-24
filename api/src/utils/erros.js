class AppError extends Error {
    constructor(status, mensagem, detalhes = null) {
        super(mensagem);
        this.status = status;
        this.detalhes = detalhes;
    }
}

const asyncHandler = (fn) => (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
};

module.exports = { AppError, asyncHandler };
