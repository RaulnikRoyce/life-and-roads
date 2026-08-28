const inicio = Date.now();

let http = 0;
let erros5xx = 0;

export const metricas = {
  toqueHttp(): void {
    http += 1;
  },
  toque5xx(): void {
    erros5xx += 1;
  },
  resumo(): { uptime_s: number; http: number; erros_5xx: number } {
    return {
      uptime_s: Math.round((Date.now() - inicio) / 1000),
      http,
      erros_5xx: erros5xx,
    };
  },
};
