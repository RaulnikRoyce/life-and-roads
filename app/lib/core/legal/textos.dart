/// Data do texto dos Termos de uso e da Privacidade que o app mostra.
/// É o que vai no aceite (ADR 0038). Mudar o texto é subir esta data, e
/// quem aceitou a anterior precisa aceitar de novo antes de a caderneta
/// voltar a subir.
const versaoTermos = '2026-09-24';

const termosResumo =
    'O life.and.roads é uma caderneta de uma motocicleta, neste aparelho. '
    'A conta é opcional. Com ela, a ficha, as datas de manutenção, o último '
    'ponto e, cifrado, o resto da caderneta vão para o servidor e voltam num '
    'celular novo. A foto fica só no aparelho. A caderneta na conta tem '
    'interruptor no bloco Conta. Uma moto, sem placa, frota ou comunidade. '
    'Uso por sua conta e risco. Os números são estimativa. Confira no painel, '
    'na bomba e na oficina. Dúvidas em contato@raulnikroyce.dev.';

const privacidadeResumo =
    'Sem conta, nada sai do aparelho. Com conta, o servidor guarda e-mail, '
    'senha (hash), ficha sem PSI, datas de manutenção, último ponto, a versão '
    'dos termos aceita e, cifrados, abastecimentos, serviços, pinos, PSI, km '
    'de óleo e corrente, validade da CNH e preços do dia. A foto nunca sobe. '
    'Desligar a caderneta na conta apaga a cópia do servidor, e excluir a '
    'conta apaga tudo que está lá. Apagar o app remove o que está no '
    'aparelho. Pedidos sobre os seus dados em contato@raulnikroyce.dev.';
