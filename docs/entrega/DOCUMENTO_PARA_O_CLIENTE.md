# Vitta Clube — Documento de funcionamento da versão 1

Este texto descreve o aplicativo como ele existe hoje, para uso no documento de entrega ao cliente. Os exemplos usam nomes fictícios (João, Maria, Ana, Farmácia Saúde do Vale) só para tornar as jornadas concretas.

O Vitta Clube é um clube de benefícios de saúde. O membro paga uma assinatura, ganha uma carteirinha digital e passa a ter desconto em consultas na clínica e em estabelecimentos parceiros (laboratório, farmácia, ótica, clínica conveniada). A consulta na Vitta não é marcada com grade de horários dentro do app: o membro combina o horário pelo WhatsApp da clínica e, no dia, a recepção confirma o desconto lendo o QR da carteirinha. No parceiro, o desconto é o percentual combinado pelo financeiro, lido no caixa do estabelecimento.

Há quatro tipos de acesso. O membro (paciente) usa o app no celular, com quatro abas: Início, Profissionais, Carteirinha e Perfil. A recepcionista usa o painel Administração no mesmo aplicativo, no aparelho do balcão. O financeiro (dono ou gestor) usa o painel Financeiro e também entra no painel operacional. O parceiro usa um painel próprio no caixa do laboratório ou da farmácia. Dependente não tem login: quem cadastra e gera o QR é o titular.

A manutenção gratuita de quatro meses, se estiver no contrato, cobre correção do que foi entregue (falhas, publicação das lojas, cobrança já ligada). Não cobre módulos novos, como Mercado Pago, agenda completa ou PIX Automático ainda não ligado no botão de pagar.

---

## 1. O que o membro vê, tela a tela

### 1.1 Primeira abertura

Ao tocar no ícone, aparece a tela inicial com o logo (Splash). O aplicativo verifica se já existe uma sessão válida. A sessão local do app dura 24 horas; se o token do servidor também estiver válido, o membro cai direto na Home. Se o cadastro veio do Google e ainda falta CPF ou telefone, o app obriga a completar os dados pessoais antes de seguir.

Quem nunca abriu o app passa por três telas de apresentação: simplicidade do dia a dia, tudo na palma da mão, e o convite para assinar o Vitta Clube. No fim, o botão “Começar agora” leva ao login. Essas três telas só aparecem uma vez naquele aparelho.

### 1.2 Entrar e cadastrar

A tela de login pede e-mail e senha. Há botão de entrar com Google. Quem esqueceu a senha usa “Esqueci minha senha”: o sistema envia um link por e-mail; ao abrir o link no celular, o membro cai na tela de nova senha, define a senha e volta a entrar.

A tela de cadastro pede nome, CPF, telefone, e-mail, senha e confirmação. É obrigatório aceitar termos de uso e política de privacidade. Há um campo opcional de código da recepcionista (exemplo: MAR0421). Esse código não identifica o paciente: ele atribui a venda à funcionária do balcão, para o ranking de indicações. O CPF precisa ser válido e único. Depois do cadastro, se CPF ou telefone estiverem incompletos, abre Dados pessoais em modo obrigatório.

Exemplo. João baixa o app na recepção. Maria, a recepcionista, mostra o código que aparece no alto do painel dela. João cola MAR0421 no cadastro, cria a conta e já fica ligado à Maria no ranking.

### 1.3 Início (Home)

A Home cumprimenta pelo primeiro nome (“Olá, João”) e tem um sino de notificações. Sem plano, aparece um cartão convidando a assinar, com o preço do plano mais barato ativo, e um banner “Sem plano”. Com plano, o banner mostra a patente (Bronze, Prata, Ouro ou Diamante) e a barra de progresso para o próximo nível. Ao tocar no banner, abre o detalhe da patente: meses como membro, consultas, o que falta para subir de nível e o percentual de desconto daquela patente nas consultas da Vitta.

Abaixo ficam três atalhos: Benefícios, Pagar e Parceiros. Em seguida, o histórico de consultas já validadas na recepção.

A tela de Benefícios é uma vitrine de texto (consultas, exames, ótica, farmácia, carteirinha, patentes). Não é a lista viva dos benefícios do plano cadastrado no financeiro.

Pagar abre o histórico de cobranças, o status da assinatura, recibo ao tocar em um pagamento, WhatsApp de suporte e o caminho para cancelar. Cancelar passa por uma tela de “o que você perde” e depois pelos motivos cadastrados pelo financeiro. Se a assinatura for Pix Automático, o cancelamento também encerra a recorrência na Woovi.

Parceiros abre o catálogo de estabelecimentos ativos.

### 1.4 Planos e pagamento

Em Perfil ou no cartão sem plano, o membro abre Planos. Lá estão os planos ativos cadastrados pelo financeiro (mensal, semestral, anual), cada um com nome, preço e lista de benefícios. Depois de escolher o período, vai para o pagamento.

Nesta versão, o caminho que cobra de verdade no cartão é a InfinityPay. O membro confirma o resumo, o app abre a página da InfinityPay no navegador, ele paga, e o aplicativo recebe o retorno (`vittaclube://payment/infinitypay/return`). Com o pagamento aprovado, a assinatura é ativada. Novos pagamentos entram na patente Bronze.

A tela de pagamento também oferece a opção Pix. Esse botão ainda não dispara o Pix Automático da Woovi nem a InfinityPay. Em produção esse caminho de Pix não conclui uma cobrança real. O contrato de entrega deve deixar isso explícito: cartão nesta versão; Pix Automático (Woovi) fica para a ligação do checkout, já preparado no servidor.

Se a assinatura estiver atrasada ou bloqueada, a carteirinha e o agendamento pedem para restaurar a conta (assinar ou regularizar) antes de liberar o QR.

### 1.5 Profissionais e “agendar”

A segunda aba lista os profissionais ativos, com especialidade e dias (ou uma observação do tipo “atende 1 vez por mês”). Dá para filtrar por especialidade. Ao tocar para agendar desconto, o membro precisa estar logado e com benefício liberado.

Na tela de agendamento ele escolhe se o desconto é para ele ou para um dependente já aprovado, escolhe uma data (previsão; o horário final é combinado no WhatsApp) e gera um QR de agendamento. Esse QR ainda não consome a cota do mês. Só consome quando a recepção validar. Em seguida o app tenta abrir o WhatsApp da clínica (número padrão configurado em Clínica, não o WhatsApp individual do médico) com uma mensagem pronta.

Exemplo. João quer nutricionista. Abre Profissionais, filtra Nutrição, toca em Dra. Ana, escolhe “para mim”, gera o QR e manda a mensagem no WhatsApp da clínica. A recepção responde o horário. No dia da consulta, João mostra a carteirinha ou o QR do agendamento no balcão.

### 1.6 Carteirinha

A terceira aba é a carteirinha: nome, código de oito dígitos (formato 8472-9103) e o botão de mostrar QR. Se houver dependentes ativos, há seletor para gerar o QR do titular ou do dependente. O QR do titular é a identidade do membro. O QR do dependente identifica aquele dependente aprovado. Sem plano ativo, a carteirinha continua visível, mas o QR não é liberado: o app pede para assinar ou restaurar a conta.

Abaixo, o histórico de usos (consultas registradas).

### 1.7 Perfil e o restante do membro

O Perfil tem: Dados pessoais (nome, CPF e telefone; e-mail não se altera aqui), Notificações (preferências de sorteios, rankings, pagamentos e novidades), Planos, Dependentes, Segurança (trocar senha), Privacidade e dados (termos e política), Seja parceiro, e Sair. O sino no topo abre a caixa de avisos.

Dados pessoais: o membro corrige nome, CPF e telefone. CPF e telefone seguem criptografados no banco.

Notificações (caixa de entrada): lista avisos enviados pela clínica (campanhas). Dá para marcar como lida. Ao tocar, pode abrir profissionais, planos ou parceiros, conforme o aviso. O push no celular usa o mesmo conteúdo, se o aparelho tiver permissão e o token registrado.

Dependentes: o titular cadastra nome, CPF, data de nascimento e parentesco. O cadastro nasce como pendente. Só depois da aprovação presencial na recepção o dependente aparece na carteirinha e no agendamento. Há limite de quantidade (na interface atual, dois) e regra de uso mensal do desconto. O dependente nunca entra com senha própria.

Seja parceiro: um estabelecimento pode se candidatar (nome, categoria, endereço, telefone, e-mail). A candidatura fica pendente até o financeiro publicar o acordo. O membro que se candidata não vira parceiro sozinho.

Privacidade: leitura dos termos e da política. Excluir conta, nesta versão, é um aviso para contato (não há botão que apaga tudo no servidor de uma vez).

---

## 2. A recepção: como se vende e como se atende

O painel da recepcionista abre com o título Administração, um texto de “como funciona” e, se ela tiver código, o cartão com o código de indicação para mostrar ao cliente na hora do cadastro.

O texto do próprio app diz: na recepção ela libera o benefício e confirma quem está no balcão; o desconto da consulta Vitta é o percentual da patente do titular, não o percentual de laboratório.

Os três passos que o app mostra para ela:

Primeiro, aprovar dependentes presencialmente na primeira visita, com documento.

Segundo, ler o QR da carteirinha (titular ou dependente ativo) ou digitar o código de oito dígitos.

Terceiro, se a consulta for na Vitta, informar o valor original: o app aplica o percentual da patente e mostra quanto o cliente economiza.

Há um botão grande “Ler QR Code” e um conjunto de cadastros e operações: profissionais, especialidades, usuários, dependentes, pagamentos (consulta), consultas, notificações, sorteios, cupons, scanner, ranking de indicações, quem indicou, candidaturas de parceiro e configurações da clínica (WhatsApp padrão e cotas).

Nem tudo que aparece no painel a recepcionista consegue gravar no banco. Cupons, por exemplo, ela pode ver; criar ou alterar é do financeiro. Aprovar uma candidatura de parceiro e transformar a pessoa em parceiro também exige o financeiro, porque só ele pode mudar o tipo de acesso da conta. No documento para o cliente, o dia a dia da recepção é: vender o clube, cadastrar, aprovar dependente, validar QR, informar valor da consulta.

### História: alguém chega no balcão sem o app (venda)

João entra na clínica porque a consulta particular está cara. Maria explica o Vitta Clube: paga um valor por mês, usa a carteirinha, tem desconto na consulta da casa e em parceiros.

Caminho mais comum nesta versão: João instala o aplicativo no próprio celular, na hora. Maria mostra o código MAR0421. João se cadastra com esse código, escolhe um plano e paga com cartão (InfinityPay). Quando o pagamento confirma, a carteirinha libera o QR. Maria já pode orientar: “Na próxima, é só abrir Carteirinha e eu leio o código.”

Se João não quiser baixar na hora, Maria pode cadastrar o membro no painel, em Usuários (nome, e-mail, CPF, telefone). Mesmo assim o pagamento da assinatura, nesta versão, é feito no app do membro (cartão). O painel da recepção não substitui o checkout.

Depois de assinar, se ele já for atender naquele dia, Maria usa o Scanner, lê o QR (ou digita o código de oito dígitos se a câmera falhar), confere o nome com o documento, informa o valor da consulta (por exemplo R$ 200). Se a patente for Bronze (10%), o app mostra que o cliente paga o equivalente ao desconto e registra quanto economizou. A cota do mês é consumida nessa validação, não no WhatsApp.

### História: membro antigo chega para consultar

João já é Bronze. Ele combinou horário no WhatsApp. Na recepção, abre a aba Carteirinha, toca em mostrar QR. Maria abre Ler QR Code, aponta a câmera, vê o nome e o status. Confere o RG. Informa o valor. Confirma. João entra para a consulta com o desconto da patente.

Se o QR não ler (tela quebrada, brilho baixo), Maria toca em digitar o código do membro, João lê os oito dígitos da carteirinha, ela confirma a mesma validação.

Se o plano estiver atrasado, o app recusa o QR. Maria orienta a regularizar em Pagar, no celular dele. Enquanto o acesso estiver bloqueado, não há desconto de clube.

### História: a filha vai consultar (dependente)

João cadastra Ana em Perfil → Dependentes. Ana fica pendente. Na primeira vez, os dois vão ao balcão com documento da Ana. Maria abre Dependentes no painel, encontra o pedido, confere a identidade e aprova. Daí em diante João, na carteirinha, escolhe Ana e mostra o QR dela. Na validação, o desconto continua sendo o da patente do titular, e a cota é a do clube do titular.

### História: indicação no balcão

Uma nova cliente diz que a Maria indicou. No cadastro, cola o código da Maria. No ranking de indicações, a Maria vê quantas indicações do mês converteram (assinatura paga). O financeiro vê a lista “Quem indicou” e pode corrigir atribuição se o código não foi preenchido.

O código da recepcionista não serve para “provar que o paciente é membro”. Para isso só valem QR da carteirinha, código de oito dígitos do membro, ou o QR de agendamento gerado no app.

### O que a recepção faz no restante do painel

Profissionais: cadastra médicos, especialidade, dias ou observação de disponibilidade, WhatsApp do profissional (o agendamento do membro, hoje, usa o WhatsApp da clínica).

Especialidades: lista usada no filtro do membro.

Usuários: busca e edita dados do membro. Não altera se a pessoa é admin ou financeiro (isso é do financeiro).

Consultas: vê e registra consultas; o registro com desconto também nasce do scanner.

Notificações: pode mandar um recado para um membro específico (lembrete, retorno). Não dispara campanha para toda a base — isso é do financeiro.

Clínica: grava o WhatsApp que o app abre no agendamento e parâmetros de dependentes.

---

## 3. O financeiro (dono)

O painel Financeiro abre com a visão gerencial: receita do mês (pagamentos aprovados), membros ativos, inadimplentes e cancelamentos, além do texto de que só o financeiro publica o percentual vivo de cada parceiro.

Ele cadastra planos e preços, patentes (badges e regras visuais de desconto na clínica), equipe (pode promover alguém a recepcionista, financeiro ou parceiro), lista de parceiros e o percentual de cada um, motivos de cancelamento e a lista de faturamento. Pelo atalho “Painel administrativo” ele opera o mesmo scanner e as mesmas filas da recepção.

Exemplo. O dono combina 15% com a Farmácia Saúde do Vale. Ele grava 15% no cadastro do parceiro. Esse é o número que o membro vê no catálogo e que o caixa da farmácia vê na validação. A farmácia não altera o percentual. Na consulta da Vitta, o desconto continua sendo o da patente (Bronze 10%, Prata 15%, e assim por diante), independente do acordo da farmácia. Os dois percentuais não se somam.

Campanha para todos os membros (divulgação, especialista da semana) também é do financeiro. A recepção manda só para um paciente por vez.

---

## 4. O parceiro

O estabelecimento aprovado entra no app com perfil de parceiro. O texto do painel diz: o membro mostra a carteirinha no caixa; a confirmação do desconto acontece no aparelho do estabelecimento, não no celular do cliente.

Passos no caixa: conferir nome com documento; ler QR ou digitar o código do membro neste aparelho; aplicar no PDV o percentual combinado com o Vitta; se informar o valor do pedido, o app mostra a economia em reais.

O parceiro cadastra a vitrine de serviços (preço cheio e preço Vita) para o membro ver no catálogo. A validação em si não depende de escolher um serviço da lista: ela é a leitura da carteirinha.

Exemplo. João vai fazer exames. No app, em Parceiros, vê “Saúde do Vale — 15%”. No laboratório, mostra a carteirinha. A atendente do lab, logada no Vitta, lê o QR, vê 15%, lança o desconto no caixa deles. Não é a recepção da clínica quem valida laboratório.

---

## 5. Notificações e divulgação

O financeiro (ou a recepção, para um único membro) redige título e texto, escolhe o tipo (divulgação, especialista, consulta, sistema) e, se quiser, o destino ao toque (abrir profissionais, planos ou parceiros).

O membro recebe na caixa de entrada (sino na Home e no Perfil) e, se aceitou a permissão do sistema, no aviso do celular. Desligar “Novidades” nas configurações faz com que campanhas de divulgação e especialista não entrem para aquele usuário.

Nesta versão o envio é imediato. Não há “agendar para amanhã às 10h” nem aviso automático de “sua consulta é amanhã”.

---

## 6. Segurança e dados (para o capítulo jurídico)

O acesso às informações é separado por perfil no banco (cada um vê o que é dele). Dados de CPF e telefone são tratados como sensíveis e gravados de forma protegida. A validação da carteirinha passa por regras no servidor (assinatura ativa, cota, desconto), não só pela tela. Há limite de tentativas em operações sensíveis (leitura de QR, disparo de campanha) para reduzir abuso.

O QR da carteirinha identifica o membro. Como qualquer carteirinha digital, um print pode ser mostrado. A mitigação operacional é a conferência do documento no balcão e a leitura no aparelho da recepção ou do parceiro, não no aparelho de um terceiro.

Login com Google não usa o Firebase como banco de dados: o Firebase só entrega o token do Google; a conta e os dados ficam no Vitta (Supabase).

---

## 7. O que esta versão entrega e o que não entrega

Esta versão entrega o clube operando: cadastro e login, planos e pagamento com cartão (InfinityPay), carteirinha com QR e código, desconto de consulta na Vitta pela patente, agendamento via WhatsApp da clínica, dependentes com aprovação no balcão, catálogo e validação em parceiros, painéis de recepção e financeiro, indicações da recepcionista, campanhas in-app e preparação de push.

Não entra nesta entrega, e não deve ser prometido no contrato como já pronto:

Pix Automático da Woovi no botão de pagar do membro (o servidor já tem as funções; o botão do app ainda não abre esse fluxo). Mercado Pago. Grade de horários no lugar do WhatsApp. Sorteio automático e participação do membro no app. Cupom na jornada do membro. Tela “Indique um amigo” no menu do membro (o código da recepcionista no cadastro, sim). Subida automática de patente disparada na Home (regras existem; o gatilho automático não está ligado). Agendar notificação. Exclusão total de conta em um toque. Relatórios financeiros avançados (gráficos, ROI de cupom). Validação de parceiro pelo celular do cliente.

Esses itens, se o cliente quiser, são evolução, não a manutenção de quatro meses.

---

## 8. Roteiro rápido para treinar a equipe

Recepcionista, no primeiro dia: entrar com o usuário admin; anotar o código de indicação; treinar Ler QR Code com um membro de teste; treinar digitar o código de oito dígitos; treinar a fila de dependentes pendentes; saber dizer “o desconto da consulta é o da patente; farmácia é outro percentual, no caixa deles”.

Membro de teste: cadastrar, pagar um plano em ambiente de homologação, abrir carteirinha, gerar QR, passar no scanner, ver a consulta aparecer na Home.

Parceiro de teste: financeiro grava o percentual; o estabelecimento entra no painel parceiro; lê a mesma carteirinha; confere que o percentual é o do acordo, não o da patente.

Financeiro: criar um plano, um profissional, um parceiro, uma campanha para um usuário de teste, e conferir o aviso no sino.

---

## 9. Como usar este texto no documento oficial

Copie os capítulos 1 a 7 para o Word de entrega. Troque os nomes fictícios pela clínica real, se quiser. No item de pagamento, deixe explícito InfinityPay no cartão. No item de consulta, deixe explícito WhatsApp + QR no balcão. No item de manutenção de quatro meses, copie o parágrafo do início (correção do entregue, não módulos novos).

O modelo visual gerado anteriormente está em `output/documents/modelo-entrega-aplicativo-vittaclube.docx`. Este arquivo é o conteúdo em português corrido, sem tabelas, para colar e revisar com o cliente.

---

## 10. Inventário falado de todas as telas

Abaixo, cada tela nomeada como o usuário vê, com o que faz. Serve de checklist de treinamento e de anexo do contrato.

### Membro

Splash: logo enquanto o app decide se manda para onboarding, login, completar cadastro, Home, ou um dos painéis de staff.

Onboarding (três páginas): textos “Simplicidade para o seu dia”, “No alcance da sua mão”, “Junte-se ao Vita Clube”, botão começar.

Login: e-mail, senha, entrar, Google, criar conta, esqueci senha.

Cadastro: nome, CPF, telefone, e-mail, senha, confirmar senha, código da recepcionista (opcional), aceite de termos e privacidade, cadastrar, Google.

Esqueci senha: e-mail e envio do link.

Redefinir senha: nova senha após o link do e-mail.

Verificar código: tela antiga de seis dígitos. Não faz parte do fluxo atual de recuperação (hoje é link). Não usar no treinamento.

Dados pessoais: nome, CPF, telefone. No primeiro Google, não dá para voltar sem sair da conta.

Home: saudação, sino, banner de patente ou convite de plano, Benefícios, Pagar, Parceiros, lista de consultas.

Detalhe da patente (folha que sobe na Home): progresso, requisitos para o próximo nível, percentual da consulta Vitta.

Benefícios: vitrine estática de vantagens.

Planos: carrossel dos planos ativos e benefícios cadastrados.

Escolher plano: período (mensal, semestral, anual) e seguir para pagar.

Pagamento: cartão (InfinityPay) ou Pix (nesta versão o Pix do botão não conclui cobrança real em produção). Resumo antes de confirmar. Links de termos.

Aguardando InfinityPay: o membro voltou do navegador; o app consulta se o pagamento foi aprovado e então ativa o plano.

Pagamentos (histórico): status da assinatura, lista, recibo, suporte, cancelar.

Cancelamento: tela de retenção e depois escolha do motivo.

Profissionais: lista e filtro por especialidade.

Agendar desconto: titular ou dependente, data prevista, gerar QR, abrir WhatsApp da clínica.

Carteirinha: nome, código, seletor de dependente, mostrar QR, histórico.

QR (folha): o código grande para a recepção ou o parceiro ler.

Parceiros: busca e lista de estabelecimentos ativos, atalho seja parceiro.

Detalhe do parceiro: percentual do acordo, endereço, instrução de mostrar a carteirinha no caixa, lista de serviços com preço cheio e preço Vita.

Seja parceiro e formulário de candidatura: dados do estabelecimento.

Caixa de notificações: lista, marcar lidas, toque que pode abrir outra tela.

Preferências de notificação: quatro interruptores (sorteios, rankings, pagamentos, novidades).

Dependentes: lista, status pendente ou ativo, cadastrar, desativar.

Formulário de dependente: nome, CPF, nascimento, parentesco.

Segurança: troca de senha.

Privacidade: termos e política; aviso de exclusão de conta por contato.

### Recepção

Administração: código de indicação, Ler QR Code, cadastros e operações.

Scanner: câmera, ou digitar código do membro. Resultado com nome e situação. Se for consulta Vitta, pede o valor original, mostra o desconto da patente e a economia, e grava.

Profissionais e formulário: nome, especialidade, dias ou observação, foto, WhatsApp, ativo.

Especialidades e formulário: nome e ativo.

Usuários e formulário: dados do membro, status. Sem promover a admin.

Dependentes (fila): pendentes para aprovar ou recusar na presença do documento.

Pagamentos (lista e detalhe): a recepção vê a lista; valores aparecem na tela. Excluir pagamento não é papel dela.

Consultas e formulário: agenda operacional.

Notificações: aba de campanhas enviadas e aba de templates. Enviar campanha para um membro, com tipo e destino ao toque.

Sorteios e formulário: cadastro de prêmio e data. Não há botão de “sortear agora” para o membro participar no app.

Cupons: a recepção vê; gravar cupom novo é do financeiro.

Ranking de indicações: só a recepcionista, por mês.

Quem indicou: lista e correção (correção pesada no financeiro).

Candidaturas de parceiro: a recepção pode ver o pedido; concluir a virada de perfil para parceiro é do financeiro.

Clínica: WhatsApp padrão e parâmetros de dependentes.

### Financeiro

Painel Financeiro: texto de dono do percentual do parceiro, métricas do mês, gestão e relatórios.

Planos: criar e precificar o que o membro vê.

Badges: níveis de patente da clínica.

Equipe: único lugar da interface para definir se a conta é membro, recepção, financeiro ou parceiro.

Parceiros (gestão): percentual vivo, endereço, ativo. Não há “criar parceiro do zero” sem passar pela candidatura.

Faturamento: mesma lista de pagamentos, com valores.

Motivos de cancelamento: textos que o membro escolhe ao sair.

Atalho para o painel da recepção.

### Parceiro

Painel Parceiro: validar desconto, números do mês, serviços, histórico, validar.

Validar: câmera ou código de oito dígitos, conferência de identidade, percentual do acordo, valor opcional, confirmar.

Serviços: vitrine (nome, preço cheio, preço Vita).

Histórico de validações.

Há telas antigas de código de balcão e check-in por senha temporária que não entram no fluxo que o membro vê hoje. O caminho oficial é carteirinha no caixa do parceiro.

