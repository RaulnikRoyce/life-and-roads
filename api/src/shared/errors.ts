export class AppError extends Error {
  status: number;
  detalhes: unknown;

  constructor(status: number, mensagem: string, detalhes: unknown = null) {
    super(mensagem);
    this.status = status;
    this.detalhes = detalhes;
  }
}

type AsyncRoute = (
  req: import('express').Request,
  res: import('express').Response,
  next: import('express').NextFunction,
) => unknown;

export const asyncHandler = (fn: AsyncRoute) => (
  req: import('express').Request,
  res: import('express').Response,
  next: import('express').NextFunction,
): void => {
  Promise.resolve(fn(req, res, next)).catch(next);
};
