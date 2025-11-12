# 📂 Índice de Arquivos do Projeto

## 🍷 Controlador de Linha de Vinhos - Estrutura Completa

---

## 📊 Visão Geral

```
Total de Arquivos: 16
├── Módulos Verilog: 10 (.v)
├── Documentação: 4 (.md)
└── Referências: 2 (.pdf)
```

---

## 🔧 MÓDULOS VERILOG (10 arquivos)

### 🏛️ Módulo Top-Level

| # | Arquivo | Tipo | Linhas | Função |
|---|---------|------|--------|--------|
| 1 | `projeto_vinho_top.v` | **ESTRUTURAL** | 261 | Integração de todos os módulos (sem lógica `always`) |

### 🧠 Unidade de Controle (FSMs)

| # | Arquivo | Tipo FSM | Linhas | Função |
|---|---------|----------|--------|--------|
| 2 | `fsm_mestre.v` | MOORE | 230 | Sequenciador principal (Cérebro do sistema) |
| 3 | `fsm_esteira.v` | **MEALY** | 62 | Controle do motor (parada instantânea) |
| 4 | `fsm_enchimento.v` | MOORE | 76 | Controle da válvula de enchimento |
| 5 | `fsm_vedacao.v` | MOORE | 106 | Controle do atuador de vedação |
| 6 | `fsm_cq_descarte.v` | MOORE | 105 | Controle de qualidade e descarte |

### 📊 Unidade de Operação (Datapath)

| # | Arquivo | Operações | Linhas | Função |
|---|---------|-----------|--------|--------|
| 7 | `contador_rolhas.v` | +1, -1, +15 | 142 | Contador com reposição automática |
| 8 | `contador_duzias.v` | +1 | 57 | Contador de garrafas processadas |
| 9 | `decodificador_display.v` | /10, %10 | 55 | Conversor BCD → 7 segmentos |

### 🛠️ Módulos Auxiliares

| # | Arquivo | Linhas | Função |
|---|---------|--------|--------|
| 10 | `debounce.v` | 66 | Tratamento de botões (anti-bounce) |

---

## 📚 DOCUMENTAÇÃO (4 arquivos)

| # | Arquivo | Páginas | Conteúdo |
|---|---------|---------|----------|
| 1 | `README.md` | 12 | **Guia Principal**: Arquitetura, testes, troubleshooting |
| 2 | `DATAPATH_DETALHADO.md` | 15 | **Análise Técnica**: Operações aritméticas e decodificadores |
| 3 | `VALIDACAO_REQUISITOS_FINAL.md` | 18 | **Validação Oficial**: Comparação item-a-item com PDF |
| 4 | `PROJETO_COMPLETO.md` | 8 | **Visão Executiva**: Resumo e checklist final |

---

## 📖 REFERÊNCIAS (2 arquivos)

| # | Arquivo | Tipo | Conteúdo |
|---|---------|------|----------|
| 1 | `TEC498_2025_2_Problema3D.pdf` | PDF | Especificação oficial do problema |
| 2 | `DE10_Lite_User_Manual.pdf` | PDF | Manual da placa FPGA |

---

## 🗂️ Organização por Função

### 📦 Arquivos para Síntese (Quartus)

```
Adicionar ao projeto Quartus:
✓ projeto_vinho_top.v        (Top-level)
✓ fsm_mestre.v
✓ fsm_esteira.v
✓ fsm_enchimento.v
✓ fsm_vedacao.v
✓ fsm_cq_descarte.v
✓ contador_rolhas.v
✓ contador_duzias.v
✓ decodificador_display.v
✓ debounce.v
```

### 📖 Arquivos de Leitura (Entendimento)

```
Ordem recomendada de leitura:
1. README.md                           (Visão geral)
2. PROJETO_COMPLETO.md                 (Resumo executivo)
3. VALIDACAO_REQUISITOS_FINAL.md       (Validação oficial)
4. DATAPATH_DETALHADO.md               (Análise técnica)
```

---

## 📊 Estatísticas do Código

### Linhas de Código Verilog

```
Módulo                      | Linhas | %
---------------------------|--------|------
projeto_vinho_top.v        |   261  | 22.5%
fsm_mestre.v               |   230  | 19.8%
contador_rolhas.v          |   142  | 12.2%
fsm_vedacao.v              |   106  | 9.1%
fsm_cq_descarte.v          |   105  | 9.0%
fsm_enchimento.v           |   76   | 6.5%
debounce.v                 |   66   | 5.7%
fsm_esteira.v              |   62   | 5.3%
contador_duzias.v          |   57   | 4.9%
decodificador_display.v    |   55   | 4.7%
---------------------------|--------|------
TOTAL                      |  1160  | 100%
```

### Distribuição por Tipo

```
Tipo              | Arquivos | Linhas | %
-----------------|----------|--------|------
ESTRUTURAL       |    1     |   261  | 22.5%
FSMs (MOORE)     |    4     |   517  | 44.6%
FSM (MEALY)      |    1     |    62  | 5.3%
Contadores       |    2     |   199  | 17.2%
Decodificador    |    1     |    55  | 4.7%
Auxiliares       |    1     |    66  | 5.7%
-----------------|----------|--------|------
TOTAL            |   10     |  1160  | 100%
```

### Páginas de Documentação

```
Documento                   | Páginas
---------------------------|--------
README.md                  |   12
DATAPATH_DETALHADO.md      |   15
VALIDACAO_REQUISITOS.md    |   18
PROJETO_COMPLETO.md        |    8
---------------------------|--------
TOTAL                      |   53
```

---

## 🎯 Mapa de Navegação

### Para Implementar na FPGA:

```
1. Abra Quartus Prime
2. Adicione os 10 arquivos .v
3. Configure projeto_vinho_top.v como top-level
4. Compile e programe
```

### Para Entender o Projeto:

```
Iniciante:
  ├─ README.md (comece aqui)
  └─ PROJETO_COMPLETO.md

Intermediário:
  ├─ VALIDACAO_REQUISITOS_FINAL.md
  └─ Código dos módulos individuais

Avançado:
  ├─ DATAPATH_DETALHADO.md
  └─ Análise das FSMs (MEALY vs MOORE)
```

### Para Validar Requisitos:

```
1. TEC498_2025_2_Problema3D.pdf (especificação)
2. VALIDACAO_REQUISITOS_FINAL.md (checklist)
3. Teste na placa física
```

---

## 🔍 Localização Rápida de Conceitos

### Onde encontrar cada conceito:

| Conceito | Arquivo Principal | Linha/Seção |
|----------|-------------------|-------------|
| **FSM MEALY** | `fsm_esteira.v` | Linhas 52-56 |
| **FSM MOORE** | `fsm_enchimento.v` | Linhas 67-83 |
| **Soma (+15)** | `contador_rolhas.v` | Linha 112 |
| **Subtração (-1)** | `contador_rolhas.v` | Linha 69 |
| **Divisão (/10)** | `decodificador_display.v` | Linha 18 |
| **Módulo (%10)** | `decodificador_display.v` | Linha 19 |
| **Debouncer** | `debounce.v` | Linhas 43-65 |
| **Reposição Auto** | `contador_rolhas.v` | Linhas 97-101 |
| **Reset Dúzias** | `contador_duzias.v` | Linhas 46-48 |
| **Alarme** | `contador_rolhas.v` | Linhas 76-81 |
| **Integração** | `projeto_vinho_top.v` | Linhas 118-259 |

---

## 📋 Checklist de Arquivos

### Antes de Entregar, Verifique:

#### ✅ Código Verilog
- [x] `projeto_vinho_top.v` (top-level estrutural)
- [x] `fsm_mestre.v` (sequenciador)
- [x] `fsm_esteira.v` (motor MEALY)
- [x] `fsm_enchimento.v` (válvula MOORE)
- [x] `fsm_vedacao.v` (vedação MOORE)
- [x] `fsm_cq_descarte.v` (CQ MOORE)
- [x] `contador_rolhas.v` (aritmética: +1, -1, +15)
- [x] `contador_duzias.v` (aritmética: +1)
- [x] `decodificador_display.v` (divisão, módulo)
- [x] `debounce.v` (tratamento de botões)

#### ✅ Documentação
- [x] `README.md` (guia principal)
- [x] `DATAPATH_DETALHADO.md` (análise aritmética)
- [x] `VALIDACAO_REQUISITOS_FINAL.md` (validação oficial)
- [x] `PROJETO_COMPLETO.md` (resumo executivo)

#### ✅ Validações
- [x] Código compila sem erros
- [x] Todos os 12 requisitos atendidos
- [x] Todos os 6 objetivos de aprendizagem cobertos
- [x] Documentação técnica completa
- [x] Pronto para síntese na FPGA

---

## 🏆 Status Final

```
╔════════════════════════════════════════════╗
║                                            ║
║   ✅ 10 Módulos Verilog Completos         ║
║   ✅ 1160 Linhas de Código                ║
║   ✅ 53 Páginas de Documentação           ║
║   ✅ 100% dos Requisitos Atendidos        ║
║   ✅ Código Sintetizável                  ║
║                                            ║
║        PROJETO PRONTO PARA ENTREGA        ║
║                  🎉 🚀                      ║
║                                            ║
╚════════════════════════════════════════════╝
```

---

**Data de Conclusão:** Novembro 2025  
**Disciplina:** TEC498 - MI Circuitos Digitais  
**Instituição:** UEFS  
**Status:** ✅ COMPLETO E VALIDADO

