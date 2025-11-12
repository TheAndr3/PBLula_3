# 🍷 Controlador de Linha de Produção de Vinhos - FPGA DE10-Lite

## 📋 Visão Geral

Este projeto implementa um controlador digital completo para simular uma linha de produção de vinhos na placa **FPGA DE10-Lite (MAX 10)** usando **Verilog HDL**.

O sistema utiliza uma **arquitetura Mestre-Escravo** com múltiplas FSMs (Finite State Machines) coordenadas, implementando os conceitos de **Máquinas de Mealy** e **Moore** de forma estratégica para garantir precisão e robustez.

---

## 🏗️ Arquitetura do Sistema

### Hierarquia de Módulos

```
projeto_vinho_top.v (ESTRUTURAL)
├── debounce.v (START)
├── fsm_mestre.v (MOORE - Sequenciador)
├── fsm_esteira.v (MEALY - Motor) x3 instâncias
├── fsm_enchimento.v (MOORE - Válvula)
├── fsm_vedacao.v (MOORE - Vedação)
├── fsm_cq_descarte.v (MOORE - Controle de Qualidade)
├── contador_rolhas.v (Contador de Rolhas)
├── contador_duzias.v (Contador de Dúzias)
├── decodificador_display.v (Rolhas) 
└── decodificador_display.v (Dúzias)
```

### Decisões Arquiteturais Críticas

#### ✅ FSM MEALY - Motor da Esteira (`fsm_esteira.v`)

**Por que MEALY?**
- A saída (`LEDR[9]` - Motor) precisa reagir **instantaneamente** à entrada (`SW[0]` - Sensor).
- Se usássemos Moore, o motor continuaria ligado por 1 ciclo de clock adicional, fazendo a "garrafa" passar do ponto.
- A lógica Mealy `motor_ativo = (estado == MOVENDO) && (!sensor_destino)` garante parada precisa.

#### ✅ FSM MOORE - Enchimento, Vedação, CQ

**Por que MOORE?**
- As saídas (`LEDR[8]` - Válvula, `LEDR[7]` - Vedação) devem ser **estáveis**.
- Imunes a ruído ou flutuações nas entradas (sensores).
- A saída depende **apenas do estado**, garantindo robustez.

#### ✅ FSM MOORE - Mestre (Sequenciador)

**Por que MOORE?**
- As saídas são **comandos** para as FSMs escravas.
- Comandos devem ser síncronos e estáveis (não reativos).
- Garante coordenação precisa do fluxo de processo.

---

## 🎮 Mapeamento de Hardware

### Entradas (Sensores Simulados)

| Componente Lógico | Hardware | Porta Verilog | Descrição |
|-------------------|----------|---------------|-----------|
| Botão START | `KEY0` | `KEY[0]` | Inicia o processo (ativo baixo) |
| Botão RESET | `KEY1` | `KEY[1]` | Reset global (ativo baixo) |
| Sensor Posição (Enchimento) | `SW0` | `SW[0]` | Detecta garrafa no enchimento |
| Sensor Nível | `SW1` | `SW[1]` | Detecta garrafa cheia |
| Sensor Posição (CQ) | `SW2` | `SW[2]` | Detecta garrafa no CQ |
| Resultado CQ | `SW3` | `SW[3]` | 0=Reprovado, 1=Aprovado |
| Sensor Final | `SW4` | `SW[4]` | Detecta garrafa no final |
| Adicionar Rolha | `SW7` | `SW[7]` | Adiciona 1 rolha manualmente |

### Saídas (Atuadores e Displays)

| Componente Lógico | Hardware | Porta Verilog | Descrição |
|-------------------|----------|---------------|-----------|
| Alarme Rolha Vazia | `LEDR0` | `LEDR[0]` | Acende quando rolhas = 0 |
| Dispensador | `LEDR5` | `LEDR[5]` | Reposição automática de rolhas |
| Descarte | `LEDR6` | `LEDR[6]` | Descarte de garrafa reprovada |
| Atuador Vedação | `LEDR7` | `LEDR[7]` | Vedação da garrafa |
| Válvula Enchimento | `LEDR8` | `LEDR[8]` | Enchimento da garrafa |
| Motor Esteira | `LEDR9` | `LEDR[9]` | Motor da esteira |
| Contador Rolhas | `HEX1-HEX0` | `HEX1`, `HEX0` | Exibe 00-99 rolhas |
| Contador Dúzias | `HEX3-HEX2` | `HEX3`, `HEX2` | Exibe 00-99 dúzias |

---

## 🔄 Fluxo de Processo

### Sequência Normal de Operação

1. **IDLE**: Operador pressiona `START (KEY0)`
   - Sistema verifica se há rolhas disponíveis
   - Se `alarme_rolha == 1`, vai para `PARADO_SEM_ROLHA`

2. **MOVIMENTO → ENCHIMENTO**
   - Motor liga (`LEDR[9]`)
   - Espera `SW[0]` detectar garrafa
   - Motor para **instantaneamente** (MEALY)

3. **ENCHIMENTO**
   - Válvula liga (`LEDR[8]`)
   - Espera `SW[1]` detectar garrafa cheia
   - Válvula desliga

4. **VEDAÇÃO**
   - Atuador liga (`LEDR[7]`)
   - Decrementa contador de rolhas
   - Aguarda 0.5s (simulação)
   - Atuador desliga

5. **MOVIMENTO → CONTROLE DE QUALIDADE**
   - Motor liga
   - Espera `SW[2]` detectar garrafa
   - Motor para

6. **CONTROLE DE QUALIDADE**
   - Verifica `SW[3]`:
     - **SW[3] = 0 (Reprovado)**: Descarte ativa (`LEDR[6]`), volta ao IDLE
     - **SW[3] = 1 (Aprovado)**: Segue para final

7. **MOVIMENTO → FINAL**
   - Motor liga
   - Espera `SW[4]` detectar garrafa
   - Motor para

8. **CONTAGEM FINAL**
   - Incrementa contador de dúzias
   - Volta ao IDLE (pronto para próxima garrafa)

---

## 📊 Lógica dos Contadores

### Contador de Rolhas (HEX1-HEX0)

- **Valor Inicial**: 20 rolhas
- **Decremento**: A cada vedação concluída
- **Alarme**: Quando `contador == 0`, `LEDR[0]` acende e motor para
- **Reposição Automática**: 
  - Quando `contador == 5`, dispensador (`LEDR[5]`) é acionado
  - Adiciona 15 rolhas (leva 1 segundo)
- **Reposição Manual**: 
  - `SW[7]` adiciona 1 rolha por vez
- **Limite Máximo**: 99 rolhas

### Contador de Dúzias (HEX3-HEX2)

- **Incremento**: Quando sensor final (`SW[4]`) detecta garrafa **aprovada**
- **Reset Manual**: Ao pressionar `START (KEY0)`
- **Reset Automático**: Quando atingir 10 dúzias

---

## 🧪 Como Testar o Sistema

### Preparação

1. Carregue o projeto na placa DE10-Lite
2. Certifique-se de que todas as chaves estão em `0` (baixo)
3. Pressione `KEY[1]` (RESET) para inicializar

### Teste Básico - Ciclo Completo

```
1. Pressione KEY[0] (START)
   → LEDR[9] (Motor) acende

2. Ligue SW[0] (Sensor Enchimento)
   → LEDR[9] apaga imediatamente (MEALY!)
   → LEDR[8] (Válvula) acende

3. Ligue SW[1] (Sensor Nível)
   → LEDR[8] apaga
   → LEDR[7] (Vedação) acende por 0.5s
   → HEX1-HEX0 decrementa (19 rolhas)

4. Após vedação:
   → LEDR[9] (Motor) acende novamente
   → Ligue SW[2] (Sensor CQ)

5. Ligue SW[3] (Aprovado)
   → LEDR[9] acende
   → Ligue SW[4] (Sensor Final)

6. HEX3-HEX2 incrementa (1 dúzia)
   → Sistema volta ao IDLE
```

### Teste de Reposição Automática

```
1. Use SW[7] para reduzir rolhas manualmente até 5
   → LEDR[5] (Dispensador) acende por 1s
   → HEX1-HEX0 mostra 20 (5 + 15)
```

### Teste de Alarme de Rolha

```
1. Use SW[7] para reduzir rolhas até 0
   → LEDR[0] (Alarme) acende
   → Motor não liga ao pressionar START
   
2. Adicione rolhas com SW[7]
   → LEDR[0] apaga
   → Sistema volta a funcionar
```

### Teste de Descarte (CQ Reprovado)

```
1. Siga o fluxo até o CQ
2. Mantenha SW[3] em 0 (Reprovado)
   → LEDR[6] (Descarte) acende por 0.5s
   → Sistema volta ao IDLE
   → HEX3-HEX2 NÃO incrementa
```

---

## 📁 Estrutura de Arquivos

```
projeto_vinho/
├── README.md                      # Este arquivo
├── projeto_vinho_top.v            # Módulo top-level ESTRUTURAL
├── fsm_mestre.v                   # FSM Mestre (MOORE)
├── fsm_esteira.v                  # FSM Esteira (MEALY)
├── fsm_enchimento.v               # FSM Enchimento (MOORE)
├── fsm_vedacao.v                  # FSM Vedação (MOORE)
├── fsm_cq_descarte.v              # FSM CQ/Descarte (MOORE)
├── contador_rolhas.v              # Contador de rolhas
├── contador_duzias.v              # Contador de dúzias
├── debounce.v                     # Debouncer de botões
├── decodificador_display.v        # Decodificador 7-seg
└── DE10_LITE.qsf                  # Arquivo de constraints (a criar)
```

---

## ⚙️ Compilação e Síntese

### Quartus Prime

1. **Criar Projeto**:
   - File → New Project Wizard
   - Selecione o dispositivo: `10M50DAF484C7G`

2. **Adicionar Arquivos**:
   - Adicione todos os arquivos `.v`
   - Defina `projeto_vinho_top.v` como top-level

3. **Pin Assignment**:
   - Use o arquivo de constraints fornecido
   - Ou configure manualmente via Pin Planner

4. **Compilação**:
   - Processing → Start Compilation
   - Aguarde a síntese completa

5. **Programação**:
   - Tools → Programmer
   - Selecione o arquivo `.sof` gerado
   - Clique em "Start" para programar a FPGA

---

## 🎯 Características Implementadas

### ✅ Requisitos Obrigatórios

- [x] Arquitetura Mestre-Escravo com múltiplas FSMs
- [x] Módulo top-level **ESTRUTURAL** (sem `always`)
- [x] Módulos filhos **COMPORTAMENTAIS**
- [x] FSM Mealy para motor (parada instantânea)
- [x] FSMs Moore para enchimento, vedação, CQ
- [x] Contador de rolhas com reposição automática
- [x] Contador de dúzias com reset automático
- [x] Debouncer para botões
- [x] Decodificador BCD para displays 7-segmentos
- [x] Alarme de falta de rolha
- [x] Controle de qualidade com descarte

### ✅ Características Adicionais

- [x] Documentação completa com diagramas
- [x] Código comentado e organizado
- [x] Sincronização de sinais (anti-metaestabilidade)
- [x] Detecção de borda para sensores
- [x] Timers para simulação de processos físicos
- [x] Proteção contra múltiplas instâncias de eventos

---

## 🔧 Parâmetros Configuráveis

### Tempos de Processo (em `fsm_vedacao.v` e `fsm_cq_descarte.v`)

```verilog
parameter TEMPO_VEDACAO = 26'd25000000;   // 0.5s a 50MHz
parameter TEMPO_DESCARTE = 26'd25000000;  // 0.5s a 50MHz
```

### Contador de Rolhas (em `contador_rolhas.v`)

```verilog
parameter MAX_ROLHAS = 7'd99;             // Máximo de rolhas
parameter LIMITE_REPOSICAO = 7'd5;        // Repõe quando atingir 5
parameter QTD_REPOSICAO = 7'd15;          // Adiciona 15 rolhas
parameter TEMPO_DISPENSADOR = 26'd50000000; // 1s a 50MHz
```

### Contador de Dúzias (em `contador_duzias.v`)

```verilog
parameter MAX_DUZIAS = 7'd10;             // Reset automático em 10
```

### Debouncer (em `debounce.v`)

```verilog
parameter COUNTER_MAX = 20'd1000000;      // 20ms a 50MHz
```

---

## 🐛 Solução de Problemas

### Motor não para ao ligar SW[0]

**Causa**: A lógica MEALY não está funcionando corretamente.
**Solução**: Verifique se o sensor está conectado ao módulo correto da esteira.

### Displays mostram valores errados

**Causa**: Problema no decodificador BCD.
**Solução**: Verifique se os valores estão dentro do range 0-99.

### Alarme não acende quando rolhas = 0

**Causa**: Lógica do contador de rolhas.
**Solução**: Verifique o módulo `contador_rolhas.v`, linha de atualização do alarme.

### Botões não respondem

**Causa**: Debouncer configurado incorretamente.
**Solução**: Aumente o tempo de debounce se necessário.

---

## 📚 Referências

- **Intel Quartus Prime**: Software de síntese para FPGA
- **DE10-Lite User Manual**: Documentação da placa
- **Verilog HDL**: IEEE Standard 1364-2005

---

## 👥 Autores

Projeto desenvolvido para a disciplina **TEC498 - Circuitos Digitais (MI)**  
**Universidade Estadual de Feira de Santana (UEFS)**  
**Problema 3 - Controlador de Linha de Vinhos**

---

## 📄 Licença

Este projeto é fornecido para fins educacionais.

---

**Última Atualização**: Novembro 2025

