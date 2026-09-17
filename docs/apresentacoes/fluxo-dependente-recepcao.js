const pptxgen = require("pptxgenjs");

const pres = new pptxgen();
pres.layout = "LAYOUT_16x9";
pres.author = "Vitta Clube";
pres.title = "Fluxo completo: Dependente + Recepção";
pres.subject = "Como o dependente usa o benefício sem conta própria";

// Palette aligned with app primary (#2C4156)
const C = {
  navy: "2C4156",
  navyDeep: "1A2A38",
  ice: "E8F1F8",
  teal: "249689",
  coral: "E8872B",
  white: "FFFFFF",
  muted: "6D7F95",
  soft: "F5F7FA",
  border: "D0D9E3",
  danger: "C23B44",
};

function addFooter(slide, page, total) {
  slide.addText(`Vitta Clube  ·  Fluxo dependente  ·  ${page}/${total}`, {
    x: 0.5,
    y: 5.25,
    w: 9,
    h: 0.25,
    fontSize: 10,
    fontFace: "Calibri",
    color: C.muted,
    margin: 0,
  });
}

const TOTAL = 9;

// ── 1. Title ──────────────────────────────────────────────
{
  const s = pres.addSlide();
  s.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 0, w: 10, h: 5.625,
    fill: { color: C.navyDeep },
  });
  s.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 0, w: 0.18, h: 5.625,
    fill: { color: C.teal },
  });
  s.addText("COMO O DEPENDENTE USA O BENEFÍCIO", {
    x: 0.7, y: 1.6, w: 8.5, h: 0.4,
    fontSize: 13, fontFace: "Calibri", color: C.teal,
    bold: true, charSpacing: 2, margin: 0,
  });
  s.addText("Fluxo completo: cadastro, QR e recepção", {
    x: 0.7, y: 2.1, w: 8.5, h: 1,
    fontSize: 32, fontFace: "Georgia", color: C.white,
    bold: true, margin: 0,
  });
  s.addText("O dependente não tem conta. O titular opera o app.\nA recepção confere a pessoa no balcão.", {
    x: 0.7, y: 3.4, w: 8, h: 0.8,
    fontSize: 16, fontFace: "Calibri", color: "B8C7D6", margin: 0,
  });
}

// ── 2. Insight central ────────────────────────────────────
{
  const s = pres.addSlide();
  s.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 0, w: 10, h: 5.625, fill: { color: C.soft },
  });
  s.addText("A regra central", {
    x: 0.5, y: 0.35, w: 9, h: 0.5,
    fontSize: 28, fontFace: "Georgia", color: C.navy, bold: true, margin: 0,
  });

  const cards = [
    { t: "Titular", d: "Tem login, assinatura e carteirinha. É a conta que paga e gera o QR.", c: C.navy },
    { t: "Dependente", d: "É um cadastro (nome, CPF, parentesco) ligado ao titular. Sem app, sem senha.", c: C.coral },
    { t: "Recepção", d: "Escaneia o QR, confere se a pessoa é quem o sistema diz e registra o valor.", c: C.teal },
  ];
  cards.forEach((card, i) => {
    const x = 0.5 + i * 3.1;
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, {
      x, y: 1.2, w: 2.9, h: 3.4,
      fill: { color: C.white },
      shadow: { type: "outer", color: "000000", blur: 8, opacity: 0.08, offset: 2 },
      rectRadius: 0.12,
    });
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, {
      x, y: 1.2, w: 2.9, h: 0.12,
      fill: { color: card.c }, rectRadius: 0.02,
    });
    s.addText(card.t, {
      x: x + 0.2, y: 1.6, w: 2.5, h: 0.5,
      fontSize: 20, fontFace: "Georgia", color: C.navy, bold: true, margin: 0,
    });
    s.addText(card.d, {
      x: x + 0.2, y: 2.3, w: 2.5, h: 1.8,
      fontSize: 14, fontFace: "Calibri", color: C.muted, margin: 0,
    });
  });
  addFooter(s, 2, TOTAL);
}

// ── 3. Journey overview ───────────────────────────────────
{
  const s = pres.addSlide();
  s.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 0, w: 10, h: 5.625, fill: { color: C.soft },
  });
  s.addText("Jornada em 5 atos", {
    x: 0.5, y: 0.35, w: 9, h: 0.5,
    fontSize: 28, fontFace: "Georgia", color: C.navy, bold: true, margin: 0,
  });

  const steps = [
    { n: "01", t: "Cadastrar", d: "Titular adiciona dependente no Perfil" },
    { n: "02", t: "Aprovar", d: "Admin aprova presencialmente (pending → active)" },
    { n: "03", t: "Agendar", d: "Titular escolhe: eu ou o dependente" },
    { n: "04", t: "QR", d: "App gera QR do agendamento (sem debitar cota)" },
    { n: "05", t: "Balcão", d: "Recepção escaneia, confere, aplica desconto" },
  ];
  steps.forEach((st, i) => {
    const y = 1.05 + i * 0.78;
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, {
      x: 0.5, y, w: 9, h: 0.68,
      fill: { color: C.white }, rectRadius: 0.08,
    });
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, {
      x: 0.65, y: y + 0.12, w: 0.55, h: 0.44,
      fill: { color: i === 4 ? C.teal : C.navy }, rectRadius: 0.06,
    });
    s.addText(st.n, {
      x: 0.65, y: y + 0.18, w: 0.55, h: 0.35,
      fontSize: 12, fontFace: "Calibri", color: C.white, bold: true,
      align: "center", margin: 0,
    });
    s.addText(st.t, {
      x: 1.45, y: y + 0.12, w: 2.2, h: 0.44,
      fontSize: 16, fontFace: "Georgia", color: C.navy, bold: true,
      valign: "middle", margin: 0,
    });
    s.addText(st.d, {
      x: 3.7, y: y + 0.12, w: 5.5, h: 0.44,
      fontSize: 14, fontFace: "Calibri", color: C.muted,
      valign: "middle", margin: 0,
    });
  });
  addFooter(s, 3, TOTAL);
}

// ── 4. Cadastro ───────────────────────────────────────────
{
  const s = pres.addSlide();
  s.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 0, w: 10, h: 5.625, fill: { color: C.soft },
  });
  s.addText("Ato 1 — Cadastro (só o titular)", {
    x: 0.5, y: 0.35, w: 9, h: 0.5,
    fontSize: 26, fontFace: "Georgia", color: C.navy, bold: true, margin: 0,
  });
  s.addText("O dependente não se cadastra. Não existe botão “sou dependente”.", {
    x: 0.5, y: 0.9, w: 9, h: 0.35,
    fontSize: 14, fontFace: "Calibri", color: C.muted, italic: true, margin: 0,
  });

  const flow = [
    "Perfil",
    "Dependentes",
    "Adicionar",
    "Nome · CPF · Nasc. · Parentesco",
    "Status: pending",
  ];
  flow.forEach((label, i) => {
    const x = 0.4 + i * 1.9;
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, {
      x, y: 1.7, w: 1.75, h: 1.5,
      fill: { color: i === 4 ? "FFF4E8" : C.white },
      line: { color: i === 4 ? C.coral : C.border, width: 1.5 },
      rectRadius: 0.1,
    });
    s.addText(String(i + 1), {
      x, y: 1.9, w: 1.75, h: 0.35,
      fontSize: 18, fontFace: "Georgia", color: i === 4 ? C.coral : C.teal,
      bold: true, align: "center", margin: 0,
    });
    s.addText(label, {
      x: x + 0.08, y: 2.35, w: 1.6, h: 0.7,
      fontSize: 12, fontFace: "Calibri", color: C.navy,
      align: "center", margin: 0,
    });
    if (i < flow.length - 1) {
      s.addText("→", {
        x: x + 1.55, y: 2.15, w: 0.4, h: 0.4,
        fontSize: 18, color: C.muted, align: "center", margin: 0,
      });
    }
  });

  s.addShape(pres.shapes.ROUNDED_RECTANGLE, {
    x: 0.5, y: 3.6, w: 9, h: 1.2,
    fill: { color: C.white }, rectRadius: 0.1,
  });
  s.addText([
    { text: "Importante: ", options: { bold: true, color: C.navy } },
    {
      text: "pending não pode agendar nem validar QR. Limite padrão: 2 dependentes (pending + active). CPF único entre dependentes ativos/pendentes.",
      options: { color: C.muted },
    },
  ], {
    x: 0.75, y: 3.85, w: 8.5, h: 0.75,
    fontSize: 14, fontFace: "Calibri", margin: 0,
  });
  addFooter(s, 4, TOTAL);
}

// ── 5. Aprovação + uso ────────────────────────────────────
{
  const s = pres.addSlide();
  s.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 0, w: 10, h: 5.625, fill: { color: C.soft },
  });
  s.addText("Atos 2–4 — Liberar e gerar o QR", {
    x: 0.5, y: 0.35, w: 9, h: 0.5,
    fontSize: 26, fontFace: "Georgia", color: C.navy, bold: true, margin: 0,
  });

  // Left card
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, {
    x: 0.5, y: 1.1, w: 4.35, h: 3.7,
    fill: { color: C.white }, rectRadius: 0.12,
  });
  s.addText("Aprovação (admin)", {
    x: 0.75, y: 1.35, w: 3.9, h: 0.4,
    fontSize: 18, fontFace: "Georgia", color: C.navy, bold: true, margin: 0,
  });
  s.addText([
    { text: "Fila de pendentes no painel admin", options: { bullet: true, breakLine: true } },
    { text: "Confirma o vínculo presencialmente", options: { bullet: true, breakLine: true } },
    { text: "Aprova → status active", options: { bullet: true, breakLine: true } },
    { text: "Ou rejeita → inactive + motivo", options: { bullet: true } },
  ], {
    x: 0.75, y: 2.0, w: 3.9, h: 2.4,
    fontSize: 14, fontFace: "Calibri", color: C.muted, margin: 0,
  });

  // Right card
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, {
    x: 5.15, y: 1.1, w: 4.35, h: 3.7,
    fill: { color: C.white }, rectRadius: 0.12,
  });
  s.addText("Agendar (titular no app)", {
    x: 5.4, y: 1.35, w: 3.9, h: 0.4,
    fontSize: 18, fontFace: "Georgia", color: C.navy, bold: true, margin: 0,
  });
  s.addText([
    { text: "Escolhe data/hora prevista", options: { bullet: true, breakLine: true } },
    { text: "Seleciona beneficiário: Titular ou Dependente X", options: { bullet: true, breakLine: true } },
    { text: "Sistema gera QR de agendamento", options: { bullet: true, breakLine: true } },
    { text: "Cota NÃO debita ainda — só no balcão", options: { bullet: true } },
  ], {
    x: 5.4, y: 2.0, w: 3.9, h: 2.4,
    fontSize: 14, fontFace: "Calibri", color: C.muted, margin: 0,
  });
  addFooter(s, 5, TOTAL);
}

// ── 6. Como o dependente “usa” na prática ─────────────────
{
  const s = pres.addSlide();
  s.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 0, w: 10, h: 5.625, fill: { color: C.soft },
  });
  s.addText("Então como o dependente usa na prática?", {
    x: 0.5, y: 0.3, w: 9, h: 0.5,
    fontSize: 24, fontFace: "Georgia", color: C.navy, bold: true, margin: 0,
  });

  s.addShape(pres.shapes.ROUNDED_RECTANGLE, {
    x: 0.5, y: 1.0, w: 9, h: 1.35,
    fill: { color: C.navy }, rectRadius: 0.1,
  });
  s.addText("Ele não “entra no app como dependente”.\nQuem leva o celular (ou o QR) é o titular — ou alguém com o telefone do titular.", {
    x: 0.75, y: 1.2, w: 8.5, h: 1,
    fontSize: 16, fontFace: "Calibri", color: C.white, margin: 0,
  });

  const scenes = [
    { t: "Cenário ideal", d: "Titular agenda para o filho, gera o QR do dependente, e o filho (ou a família) mostra esse QR na recepção." },
    { t: "No balcão", d: "Scanner lê o token → backend vê beneficiary = dependente João → desconto do plano do titular → cota do João." },
    { t: "Sem app do dependente", d: "João nunca faz login. O “direito” dele existe só como cadastro + cota + QR de agendamento nominal." },
  ];
  scenes.forEach((sc, i) => {
    const x = 0.5 + i * 3.1;
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, {
      x, y: 2.65, w: 2.95, h: 2.1,
      fill: { color: C.white }, rectRadius: 0.1,
    });
    s.addText(sc.t, {
      x: x + 0.15, y: 2.85, w: 2.65, h: 0.4,
      fontSize: 14, fontFace: "Georgia", color: C.teal, bold: true, margin: 0,
    });
    s.addText(sc.d, {
      x: x + 0.15, y: 3.3, w: 2.65, h: 1.25,
      fontSize: 12, fontFace: "Calibri", color: C.muted, margin: 0,
    });
  });
  addFooter(s, 6, TOTAL);
}

// ── 7. Dois tipos de QR ───────────────────────────────────
{
  const s = pres.addSlide();
  s.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 0, w: 10, h: 5.625, fill: { color: C.soft },
  });
  s.addText("Dois QRs — não confundir", {
    x: 0.5, y: 0.35, w: 9, h: 0.5,
    fontSize: 26, fontFace: "Georgia", color: C.navy, bold: true, margin: 0,
  });

  // Card A
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, {
    x: 0.5, y: 1.1, w: 4.35, h: 3.7,
    fill: { color: C.white }, rectRadius: 0.12,
  });
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, {
    x: 0.5, y: 1.1, w: 4.35, h: 0.55,
    fill: { color: C.navy }, rectRadius: 0.08,
  });
  s.addText("Carteirinha do titular", {
    x: 0.7, y: 1.2, w: 4, h: 0.4,
    fontSize: 16, fontFace: "Georgia", color: C.white, bold: true, margin: 0,
  });
  s.addText([
    { text: "Payload: userId (UUID) ou código 8 dígitos", options: { bullet: true, breakLine: true } },
    { text: "RPC: validate_member_qr", options: { bullet: true, breakLine: true } },
    { text: "Sempre trata como o titular", options: { bullet: true, breakLine: true } },
    { text: "Não escolhe dependente", options: { bullet: true, breakLine: true } },
    { text: "Risco: outra pessoa com o celular passa como titular", options: { bullet: true } },
  ], {
    x: 0.75, y: 1.9, w: 3.9, h: 2.6,
    fontSize: 13, fontFace: "Calibri", color: C.muted, margin: 0,
  });

  // Card B
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, {
    x: 5.15, y: 1.1, w: 4.35, h: 3.7,
    fill: { color: C.white }, rectRadius: 0.12,
  });
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, {
    x: 5.15, y: 1.1, w: 4.35, h: 0.55,
    fill: { color: C.teal }, rectRadius: 0.08,
  });
  s.addText("QR de agendamento", {
    x: 5.35, y: 1.2, w: 4, h: 0.4,
    fontSize: 16, fontFace: "Georgia", color: C.white, bold: true, margin: 0,
  });
  s.addText([
    { text: "Payload: token opaco (com “.”)", options: { bullet: true, breakLine: true } },
    { text: "RPC: validate_dependent_qr", options: { bullet: true, breakLine: true } },
    { text: "Amarrado a titular + beneficiário", options: { bullet: true, breakLine: true } },
    { text: "Cota por beneficiário; uso único", options: { bullet: true, breakLine: true } },
    { text: "Caminho correto para o dependente", options: { bullet: true } },
  ], {
    x: 5.4, y: 1.9, w: 3.9, h: 2.6,
    fontSize: 13, fontFace: "Calibri", color: C.muted, margin: 0,
  });
  addFooter(s, 7, TOTAL);
}

// ── 8. Tela de conferência ────────────────────────────────
{
  const s = pres.addSlide();
  s.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 0, w: 10, h: 5.625, fill: { color: C.soft },
  });
  s.addText("Ato 5+ — Conferência na recepção", {
    x: 0.5, y: 0.3, w: 9, h: 0.45,
    fontSize: 24, fontFace: "Georgia", color: C.navy, bold: true, margin: 0,
  });
  s.addText("O que vamos implementar: sistema aprova o direito · humano confirma a pessoa", {
    x: 0.5, y: 0.8, w: 9, h: 0.35,
    fontSize: 13, fontFace: "Calibri", color: C.muted, italic: true, margin: 0,
  });

  const pipe = [
    { n: "1", t: "Escanear", d: "QR ou código" },
    { n: "2", t: "Resultado", d: "Nome · patente · % · usos" },
    { n: "3", t: "Conferir", d: "Identidade confere?" },
    { n: "4", t: "Valor", d: "Desconto + gravar" },
  ];
  pipe.forEach((p, i) => {
    const x = 0.5 + i * 2.35;
    s.addShape(pres.shapes.OVAL, {
      x: x + 0.7, y: 1.35, w: 0.55, h: 0.55,
      fill: { color: i === 2 ? C.coral : C.navy },
    });
    s.addText(p.n, {
      x: x + 0.7, y: 1.45, w: 0.55, h: 0.4,
      fontSize: 16, fontFace: "Calibri", color: C.white, bold: true,
      align: "center", margin: 0,
    });
    s.addText(p.t, {
      x, y: 2.1, w: 2.1, h: 0.35,
      fontSize: 15, fontFace: "Georgia", color: C.navy, bold: true,
      align: "center", margin: 0,
    });
    s.addText(p.d, {
      x, y: 2.45, w: 2.1, h: 0.4,
      fontSize: 12, fontFace: "Calibri", color: C.muted,
      align: "center", margin: 0,
    });
    if (i < 3) {
      s.addText("→", {
        x: x + 1.9, y: 1.4, w: 0.4, h: 0.4,
        fontSize: 20, color: C.border, margin: 0,
      });
    }
  });

  s.addShape(pres.shapes.ROUNDED_RECTANGLE, {
    x: 0.5, y: 3.15, w: 9, h: 1.7,
    fill: { color: C.white }, rectRadius: 0.1,
  });
  s.addText("Na tela de conferência a recepção vê", {
    x: 0.75, y: 3.35, w: 8.5, h: 0.35,
    fontSize: 14, fontFace: "Georgia", color: C.navy, bold: true, margin: 0,
  });
  s.addText([
    { text: "Nome do beneficiário (titular ou dependente)", options: { bullet: true, breakLine: true } },
    { text: "Se dependente: “Dependente de [Titular]”", options: { bullet: true, breakLine: true } },
    { text: "Patente + % de desconto + usos restantes", options: { bullet: true, breakLine: true } },
    { text: "Botões: Identidade confere  ·  Não confere  ·  Escanear de novo", options: { bullet: true } },
  ], {
    x: 0.75, y: 3.75, w: 8.5, h: 1.0,
    fontSize: 13, fontFace: "Calibri", color: C.muted, margin: 0,
  });
  addFooter(s, 8, TOTAL);
}

// ── 9. Fechamento ─────────────────────────────────────────
{
  const s = pres.addSlide();
  s.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 0, w: 10, h: 5.625,
    fill: { color: C.navyDeep },
  });
  s.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 0, w: 0.18, h: 5.625,
    fill: { color: C.teal },
  });
  s.addText("Em uma frase", {
    x: 0.7, y: 1.3, w: 8.5, h: 0.4,
    fontSize: 14, fontFace: "Calibri", color: C.teal, bold: true, margin: 0,
  });
  s.addText("O dependente usa o benefício via o app do titular + QR de agendamento no nome dele; a recepção valida quem está no balcão.", {
    x: 0.7, y: 1.85, w: 8.5, h: 1.2,
    fontSize: 22, fontFace: "Georgia", color: C.white, margin: 0,
  });
  s.addText("Próximo passo de produto: card rico + gate de identidade antes de registrar valor.", {
    x: 0.7, y: 3.4, w: 8.5, h: 0.6,
    fontSize: 14, fontFace: "Calibri", color: "B8C7D6", margin: 0,
  });
}

pres.writeFile({
  fileName: "docs/apresentacoes/fluxo-dependente-recepcao.pptx",
}).then(() => console.log("OK: docs/apresentacoes/fluxo-dependente-recepcao.pptx"));
