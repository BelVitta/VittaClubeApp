<!--
Sync Impact Report
Version change: template -> 1.0.0
Modified principles:
- Template placeholders -> I. Resultado de Negocio em Cada Funcionalidade
- Template placeholders -> II. Confianca, Conversao e Conteudo Real
- Template placeholders -> III. Experiencia Mobile-First, Acessivel e Clara
- Template placeholders -> IV. Qualidade Tecnica, Clean Architecture e Manutencao
- Template placeholders -> V. Testes Automatizados, Performance e SEO Local
Added sections:
- Padroes Obrigatorios de Produto, UX, UI e Conteudo
- Fluxo de Desenvolvimento e Quality Gates
Removed sections:
- Nenhuma secao substantiva; apenas placeholders do template foram substituidos.
Templates requiring updates:
- updated: .specify/templates/plan-template.md
- updated: .specify/templates/spec-template.md
- updated: .specify/templates/tasks-template.md
- not present: .specify/templates/commands/*.md
Follow-up TODOs: none
-->

# Vitta Clube Constitution

## Core Principles

### I. Resultado de Negocio em Cada Funcionalidade
Toda funcionalidade MUST existir para atender um objetivo de negocio claro:
gerar contato, aumentar conversao, reforcar confianca, melhorar retencao,
reduzir friccao operacional ou entregar valor direto ao cliente da clinica.
Funcionalidades sem objetivo mensuravel, sem usuario definido ou sem relacao
com o cartao fidelidade MUST NOT ser planejadas ou implementadas.

Cada especificacao MUST declarar o resultado esperado, a jornada prioritaria,
o criterio de sucesso e como a funcionalidade sera testada de forma
independente. Escopo adicional, automacoes e complexidade tecnica MUST ser
justificados por impacto real, nao por preferencia estetica ou conveniencia
interna.

### II. Confianca, Conversao e Conteudo Real
O aplicativo MUST transmitir profissionalismo ja na primeira tela. O usuario
precisa entender rapidamente a proposta do cartao fidelidade, o beneficio
principal, a legitimidade da clinica e o proximo passo recomendado.

Confianca nao pode ser presumida; ela MUST ser construida com prova visivel,
como dados reais da clinica, beneficios verificaveis, informacoes de contato,
localizacao, horarios, politicas claras, depoimentos reais quando disponiveis
e elementos consistentes de marca. CTAs importantes MUST ser visiveis,
estrategicos, acionaveis e coerentes com o momento da jornada.

Conteudos vagos, genericos ou com cara de placeholder MUST NOT ser aceitos em
entregas. Textos, labels, mensagens de erro, empty states e chamadas comerciais
MUST ser especificos, uteis e adequados ao contexto de uma clinica real.

### III. Experiencia Mobile-First, Acessivel e Clara
O produto MUST ser desenhado e validado primeiro para uso mobile. A interface
MUST priorizar clareza, hierarquia visual, navegacao simples, leitura rapida,
toques confortaveis e conclusao eficiente das acoes principais. Um aplicativo
bonito, mas lento, confuso ou ruim no mobile, e uma falha de qualidade.

Acessibilidade e requisito, nao acabamento opcional. Fluxos MUST manter
semantica correta, contraste suficiente, foco navegavel, textos legiveis,
alternativas para midia relevante, estados perceptiveis e compatibilidade com
tecnologias assistivas sempre que aplicavel. A estetica MUST apoiar a
usabilidade; decoracao sem funcao, excesso visual e animacoes que prejudiquem
clareza ou performance MUST NOT ser usadas.

### IV. Qualidade Tecnica, Clean Architecture e Manutencao
A implementacao MUST seguir codigo limpo, organizado e simples. O projeto MUST
manter separacao clara por features e camadas, preservando limites de
responsabilidade entre apresentacao, dominio, aplicacao e infraestrutura
quando a tecnologia permitir. Regras de negocio MUST ficar testaveis e nao
acopladas diretamente a detalhes de UI, rede, armazenamento ou frameworks.

Hacks, improvisos, duplicacao desnecessaria, nomes vagos, funcoes extensas e
complexidade sem justificativa MUST NOT ser aceitos. Dependencias e abstracoes
MUST resolver problemas reais e ser coerentes com os padroes existentes do
codigo. Mudancas MUST preservar manutencao futura, rastreabilidade por feature
e facilidade de revisao.

### V. Testes Automatizados, Performance e SEO Local
Testes automatizados sao obrigatorios. Cada feature MUST incluir testes
adequados ao risco: unitarios para regras e formatadores, widget/UI para
componentes e estados criticos, integracao para jornadas de negocio e
regressao para bugs corrigidos. Testes MUST ser definidos antes ou junto da
implementacao e executados como gate de qualidade.

Performance e parte da qualidade. Telas e fluxos MUST ter carregamento rapido,
resposta fluida, uso controlado de recursos e tratamento claro de loading,
erro, vazio e indisponibilidade. Decisoes visuais, imagens, animacoes,
consultas e dependencias MUST considerar impacto em tempo de carregamento,
memoria e fluidez.

Quando houver superficie web ou conteudo indexavel, SEO local e estrutura
semantica MUST ser tratados desde a especificacao: titulos claros, hierarquia
correta, metadados relevantes, dados locais da clinica, conteudo unico e
marcacao adequada quando aplicavel.

## Padroes Obrigatorios de Produto, UX, UI e Conteudo

Toda entrega MUST demonstrar:

- objetivo de negocio explicito e criterio de sucesso mensuravel;
- primeira tela profissional, clara e orientada a acao;
- CTA primario visivel e CTAs secundarios coerentes com a jornada;
- provas de confianca proporcionais ao risco percebido pelo usuario;
- conteudo realista, especifico e sem placeholders;
- layout mobile-first sem sobreposicao, cortes, textos ilegiveis ou controles
  pequenos demais;
- estados de loading, vazio, erro, sucesso e indisponibilidade;
- acessibilidade verificavel em semantica, foco, contraste e leitura;
- consistencia visual com um sistema de cores, tipografia, espacamentos e
  componentes reutilizaveis;
- SEO local e semantica quando a entrega tiver telas web ou conteudo publico.

Simplicidade com padrao profissional e obrigatoria. A solucao mais simples que
atende aos requisitos, mantem credibilidade e preserva evolucao futura deve
ser preferida. Qualquer aumento de escopo, dependencia ou complexidade MUST
ser registrado no plano com justificativa e alternativa mais simples rejeitada.

## Fluxo de Desenvolvimento e Quality Gates

Antes da implementacao, cada feature MUST passar por verificacao de:

- valor de negocio, publico-alvo e jornada prioritaria;
- requisitos de conversao, confianca, conteudo e CTAs;
- arquitetura por feature e separacao de camadas;
- estrategia de testes automatizados;
- requisitos de acessibilidade, performance, SEO local e estados de UI;
- riscos, dependencias e decisoes tecnicas relevantes.

Durante a implementacao, cada historia de usuario MUST permanecer
independentemente testavel. Tarefas MUST incluir caminhos de teste, arquivos
alvo e criterios de validacao. Nenhuma historia e considerada concluida sem
testes automatizados executados, verificacao mobile, revisao de acessibilidade
basica e validacao de que CTAs, conteudo e estados de UI atendem a esta
constituicao.

## Governance

Esta constituicao prevalece sobre preferencias ad hoc, decisoes esteticas e
conveniencias de implementacao. Specs, planos, tarefas, revisoes e entregas
MUST verificar conformidade com estes principios.

Alteracoes nesta constituicao MUST:

- explicar a motivacao e o impacto esperado;
- atualizar templates e documentos dependentes no mesmo conjunto de mudancas;
- registrar a mudanca no Sync Impact Report;
- seguir versionamento semantico.

Versionamento:

- MAJOR para remocao ou redefinicao incompatavel de principios;
- MINOR para novo principio, nova secao normativa ou expansao material;
- PATCH para ajustes editoriais, exemplos e esclarecimentos sem mudanca de
  governanca.

Revisoes de conformidade MUST bloquear entregas com conteudo placeholder,
ausencia de objetivo de negocio, falhas mobile criticas, falta de testes
automatizados, problemas basicos de acessibilidade, degradacao relevante de
performance, arquitetura improvisada ou complexidade injustificada.

**Version**: 1.0.0 | **Ratified**: 2026-06-01 | **Last Amended**: 2026-06-01
