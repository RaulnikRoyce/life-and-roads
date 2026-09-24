/// Data do texto dos Termos de uso e da Privacidade que o app mostra.
/// É o que vai no aceite (ADR 0038). Mudar o texto é subir esta data, e
/// quem aceitou a anterior precisa aceitar de novo antes de a caderneta
/// voltar a subir.
const versaoTermos = '2026-09-24';

const termosResumo =
    'O life.and.roads é uma caderneta de uma motocicleta, neste aparelho. '
    'A conta é opcional e só replica ficha, datas de manutenção e o último ponto. '
    'Uma moto, sem placa, frota ou comunidade. Uso por sua conta e risco. '
    'Os números são estimativa. Confira no painel, na bomba e na oficina.';

const privacidadeResumo =
    'Sem login, nada sai do aparelho. Com conta, e-mail, senha (hash), ficha sem PSI, '
    'datas de manutenção e o último ponto. Foto, pins, posto e oficina não sobem. '
    'Excluir a conta no app apaga os dados remotos. Apagar o app remove o local.';
