# Parceiros — Formas de Validar Desconto

> Documento de apresentacao para o cliente.
> Objetivo: definir como o parceiro (laboratorio, clinica) valida que o usuario tem direito ao desconto Vita Clube.

---

## Contexto

- O usuario do Vita Clube vai ao parceiro e precisa comprovar que tem desconto
- O parceiro pode nao ter estrutura tecnologica avancada
- A solucao precisa ser simples para o atendente e segura contra fraudes
- Tudo pelo app do usuario ou, no maximo, um painel web para o parceiro

---

## 1. Codigo do Parceiro no App do Usuario

O parceiro tem um codigo fixo (ex: `LAB-SAUDE-2024`). O usuario abre o app, vai em "Usar Desconto", digita o codigo do parceiro, e o app registra o uso.

**Fluxo:**
```
Atendente informa o codigo → Usuario digita no app → App valida e mostra comprovante na tela
```

**Seguranca:**
- RISCO: codigo fixo vaza facil (foto, boca a boca)
- Qualquer pessoa com o codigo poderia simular uso
- Nao garante que o usuario esta fisicamente no parceiro

**Mitigacao possivel:** rotacionar o codigo semanalmente e enviar ao parceiro por email/WhatsApp.

| Facilidade parceiro | Facilidade usuario | Seguranca | Custo |
|---|---|---|---|
| Alta | Alta | Baixa | Zero |

---

## 2. Codigo Rotativo do Parceiro (Muda por Periodo)

Igual ao anterior, mas o codigo muda automaticamente (diario, semanal ou por turno). O parceiro recebe o novo codigo por email/WhatsApp automatico toda manha.

**Fluxo:**
```
Sistema envia codigo do dia ao parceiro (07h) → Atendente informa ao usuario → Usuario digita no app
```

**Seguranca:**
- Codigo vazado so vale por 1 dia/turno
- Parceiro precisa checar email/WhatsApp todo dia
- Ainda depende do atendente informar verbalmente

| Facilidade parceiro | Facilidade usuario | Seguranca | Custo |
|---|---|---|---|
| Alta | Alta | Media | Zero |

---

## 3. QR Code Fixo no Balcao do Parceiro

O parceiro imprime um QR Code e deixa no balcao/recepcao. O usuario escaneia com o app, o app valida a assinatura e registra o desconto.

**Fluxo:**
```
Usuario abre app → Escaneia QR no balcao → App confirma: "Desconto de 10% aplicado no Lab Saude"
```

**Seguranca:**
- RISCO: alguem pode tirar foto do QR e usar em outro lugar
- Nao garante presenca fisica (foto do QR circula)

**Mitigacao possivel:** combinar com geolocalizacao (opcao 7).

| Facilidade parceiro | Facilidade usuario | Seguranca | Custo |
|---|---|---|---|
| Muito alta | Alta | Baixa | Impressao do QR |

---

## 4. QR Code Rotativo no Painel Web do Parceiro

O parceiro acessa um painel web simples (uma unica pagina com login) que exibe um QR Code que muda a cada 1-5 minutos. O usuario escaneia com o app.

**Fluxo:**
```
Parceiro abre pagina web no tablet/computador → QR muda a cada 2 min → Usuario escaneia → App valida
```

**Seguranca:**
- QR muda constantemente, foto antiga nao funciona
- Token com TTL curto (2-5 min)
- Precisa de internet no parceiro e um dispositivo com tela

**Nota:** o painel e apenas uma pagina que mostra o QR, nao e um sistema complexo. Pode rodar num tablet velho no balcao.

| Facilidade parceiro | Facilidade usuario | Seguranca | Custo |
|---|---|---|---|
| Media | Alta | Alta | Zero (tablet que ja tenham) |

---

## 5. Usuario Gera QR no App → Atendente Confere Visualmente

Inverso: o usuario gera um QR/carteirinha digital no app com elementos anti-fraude (animacao, timestamp ao vivo, codigo do dia). O atendente olha a tela do usuario e confere.

**Fluxo:**
```
Usuario abre "Carteirinha Parceiro" no app → Mostra tela com nome, badge, desconto, animacao ao vivo
Atendente confere: nome bate com documento? tela esta animada (nao e screenshot)?
```

**Seguranca:**
- Animacao/gradiente ao vivo impede screenshot
- Conferencia visual depende do atendente prestar atencao
- Nao ha registro digital do uso (a menos que combine com outra opcao)

| Facilidade parceiro | Facilidade usuario | Seguranca | Custo |
|---|---|---|---|
| Muito alta | Alta | Media | Zero |

---

## 6. Codigo OTP no App do Usuario (Tipo Token Bancario)

O usuario gera no app um codigo numerico de 6 digitos que expira em 5 minutos (como Google Authenticator). O atendente digita esse codigo no painel web para validar.

**Fluxo:**
```
Usuario abre app → "Gerar codigo" → 483 291 (expira 14:35)
Atendente digita 483291 na pagina web → Tela: "✅ Maria Silva | Ouro | 10%"
```

**Seguranca:**
- Codigo expira rapido, single-use
- Atendente valida digitalmente (nao e visual)
- Registro completo de cada uso

**Nota:** a pagina de validacao do atendente e uma tela simples com um campo de input, nao e um painel completo.

| Facilidade parceiro | Facilidade usuario | Seguranca | Custo |
|---|---|---|---|
| Media | Alta | Alta | Zero |

---

## 7. Geolocalizacao — Desbloqueia Desconto Perto do Parceiro

O desconto so aparece/funciona quando o usuario esta fisicamente proximo do parceiro (raio de 100-200m). O app usa GPS para validar.

**Fluxo:**
```
Usuario abre aba Parceiros → App detecta GPS → "Voce esta no Lab Saude" → Botao "Usar desconto" liberado
```

**Seguranca:**
- Garante presenca fisica
- RISCO: GPS pode ser falsificado (mock location) por usuarios avancados
- Nao envolve o parceiro em nada — tudo acontece no app

**Mitigacao:** detectar apps de mock location no dispositivo.

| Facilidade parceiro | Facilidade usuario | Seguranca | Custo |
|---|---|---|---|
| Total (nao faz nada) | Alta | Media-Alta | Zero |

---

## 8. Check-in no App + Confirmacao do Parceiro por SMS/WhatsApp

O usuario faz "check-in" no parceiro pelo app. O parceiro recebe uma notificacao (SMS ou WhatsApp) e responde "S" para confirmar.

**Fluxo:**
```
Usuario: "Check-in no Lab Saude" → Parceiro recebe WhatsApp: "Maria Silva quer usar desconto 10%. Confirma? S/N"
Parceiro responde "S" → App do usuario: "✅ Desconto confirmado"
```

**Seguranca:**
- Dupla confirmacao (usuario + parceiro)
- Registro completo
- Parceiro so precisa responder uma mensagem

**Nota:** pode ser automatizado com WhatsApp Business API ou ate manualmente no inicio.

| Facilidade parceiro | Facilidade usuario | Seguranca | Custo |
|---|---|---|---|
| Alta | Media (espera confirmacao) | Alta | WhatsApp API (~R$150/mes) ou manual |

---

## 9. NFC / Aproximacao (Tap to Validate)

O parceiro tem um tag NFC no balcao (adesivo de R$2). O usuario aproxima o celular, o app le o tag e registra o uso do desconto automaticamente.

**Fluxo:**
```
Adesivo NFC no balcao → Usuario aproxima celular → App: "Desconto aplicado no Lab Saude"
```

**Seguranca:**
- Exige presenca fisica (NFC tem alcance de ~4cm)
- Dificil de fraudar
- RISCO: tag pode ser clonado (mas e barato trocar)

**Limitacao:** nem todo celular tem NFC (maioria dos Android tem, iPhones a partir do 7).

| Facilidade parceiro | Facilidade usuario | Seguranca | Custo |
|---|---|---|---|
| Muito alta | Muito alta | Alta | ~R$2-5 por tag |

---

## 10. Combinacao Recomendada: QR Fixo + Geolocalizacao + OTP

Combinar metodos para equilibrar seguranca e facilidade. O app exige **2 de 3** fatores para validar:

**Fatores:**
1. QR Code fixo do parceiro (escaneado no local)
2. Geolocalizacao (GPS confirma que esta perto)
3. Codigo OTP (atendente digita na pagina web de validacao)

**Fluxo simplificado (dia a dia):**
```
Usuario escaneia QR no balcao + GPS confirma localizacao → Desconto validado automaticamente
```

**Fluxo fallback (GPS ruim / ambiente fechado):**
```
Usuario escaneia QR + Gera OTP → Atendente digita OTP na pagina → Validado
```

**Seguranca:**
- QR vazado sozinho nao funciona (precisa de GPS ou OTP)
- GPS sozinho nao funciona (precisa de QR ou OTP)
- Fraude exige burlar dois sistemas simultaneamente

| Facilidade parceiro | Facilidade usuario | Seguranca | Custo |
|---|---|---|---|
| Alta | Alta | Muito alta | Zero |

---

## Resumo Comparativo

| # | Metodo | Facilidade Parceiro | Seguranca | Custo | Offline? |
|---|--------|-------------------|-----------|-------|----------|
| 1 | Codigo fixo | ★★★★★ | ★★ | Zero | Sim |
| 2 | Codigo rotativo | ★★★★ | ★★★ | Zero | Sim |
| 3 | QR fixo no balcao | ★★★★★ | ★★ | ~Zero | Sim |
| 4 | QR rotativo (painel) | ★★★ | ★★★★★ | Zero | Nao |
| 5 | Carteirinha digital | ★★★★★ | ★★★ | Zero | Sim |
| 6 | Codigo OTP | ★★★ | ★★★★★ | Zero | Nao |
| 7 | Geolocalizacao | ★★★★★ | ★★★★ | Zero | Sim |
| 8 | Check-in + WhatsApp | ★★★★ | ★★★★★ | ~R$150/mes | Nao |
| 9 | NFC | ★★★★★ | ★★★★★ | ~R$5/tag | Sim |
| 10 | Combinacao (QR+GPS+OTP) | ★★★★ | ★★★★★ | Zero | Parcial |

---

## Proximos Passos

1. Definir qual(is) metodo(s) atende(m) melhor a realidade dos parceiros atuais
2. Considerar comecar simples (1-2 metodos) e evoluir conforme a base cresce
3. Definir o schema de parceiros e exames no Supabase
4. Implementar a aba "Parceiros" no app
