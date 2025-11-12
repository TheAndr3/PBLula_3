# 🧮 Unidade de Operação (Datapath) - Análise Detalhada

## 📋 Visão Geral

Este documento detalha a **Unidade de Operação (Datapath)** do Controlador de Linha de Vinhos, focando especialmente nos **circuitos aritméticos** (somadores/subtratores) e nos **decodificadores** BCD para displays de 7 segmentos.

---

## 🔢 1. LÓGICA ARITMÉTICA NOS CONTADORES

### 1.1 Contador de Rolhas (`contador_rolhas.v`)

Este é o módulo mais complexo em termos de operações aritméticas. Implementa **três operações distintas**:

#### ✅ **Operação 1: SUBTRAÇÃO (-1) - Decremento na Vedação**

**Localização:** Linhas 67-74

```verilog
else if (pulso_decrementar && contador_valor > 0) begin
    // OPERAÇÃO ARITMÉTICA: SUBTRAÇÃO
    contador_valor <= contador_valor - 1;
    
    if (contador_valor == 1) begin
        // Vai ficar em 0 após o decremento
        alarme_rolha_vazia <= 1'b1;
    end
end
```

**Descrição:**
- **Operador Aritmético**: `-` (subtrator de 7 bits)
- **Entrada**: `contador_valor` (7 bits, range 0-99)
- **Operação**: Subtrai 1 unidade do valor atual
- **Circuito Sintetizado**: Subtrator binário de 7 bits com borrow
- **Condição de Guarda**: `contador_valor > 0` (evita underflow)
- **Trigger**: Pulso de `decrementar` (vem da FSM de vedação)

**Exemplo de Execução:**
```
Valor Atual: 20 (0010100)
Operação:    20 - 1
Resultado:   19 (0010011)
```

#### ✅ **Operação 2: ADIÇÃO (+1) - Reposição Manual**

**Localização:** Linhas 63-66

```verilog
else if (pulso_adicionar && contador_valor < MAX_ROLHAS) begin
    // OPERAÇÃO ARITMÉTICA: ADIÇÃO
    contador_valor <= contador_valor + 1;
    alarme_rolha_vazia <= 1'b0;
end
```

**Descrição:**
- **Operador Aritmético**: `+` (somador de 7 bits)
- **Entrada**: `contador_valor` (7 bits)
- **Operação**: Adiciona 1 unidade ao valor atual
- **Circuito Sintetizado**: Somador binário de 7 bits com carry
- **Condição de Guarda**: `contador_valor < MAX_ROLHAS` (evita overflow acima de 99)
- **Trigger**: Borda de subida de `SW[7]` (detecção de pulso)

**Exemplo de Execução:**
```
Valor Atual: 5 (0000101)
Operação:    5 + 1
Resultado:   6 (0000110)
```

#### ✅ **Operação 3: ADIÇÃO (+15) - Reposição Automática**

**Localização:** Linhas 109-115

```verilog
if (timer_dispensador >= TEMPO_DISPENSADOR) begin
    // OPERAÇÃO ARITMÉTICA: ADIÇÃO COM CONSTANTE
    if (contador_valor + QTD_REPOSICAO <= MAX_ROLHAS) begin
        contador_valor <= contador_valor + QTD_REPOSICAO;
    end else begin
        contador_valor <= MAX_ROLHAS;
    end
    // ...
end
```

**Descrição:**
- **Operador Aritmético**: `+` (somador de 7 bits)
- **Entrada**: `contador_valor` (7 bits)
- **Constante**: `QTD_REPOSICAO = 15` (0001111)
- **Operação**: Adiciona 15 unidades ao valor atual
- **Circuito Sintetizado**: Somador binário de 7 bits com constante hardwired
- **Proteção de Overflow**: Verifica se soma ultrapassa 99, se sim, satura em 99
- **Trigger**: Após 1 segundo de ativação do dispensador

**Exemplo de Execução:**
```
Cenário 1 (Normal):
Valor Atual: 5 (0000101)
Operação:    5 + 15
Resultado:   20 (0010100)

Cenário 2 (Saturação):
Valor Atual: 90 (1011010)
Operação:    90 + 15 = 105
Verificação: 105 > 99
Resultado:   99 (1100011) - SATURADO
```

#### ✅ **Operação 4: INCREMENTO DE TIMER (+1)**

**Localização:** Linha 106

```verilog
timer_dispensador <= timer_dispensador + 1;
```

**Descrição:**
- **Operador Aritmético**: `+` (somador de 26 bits)
- **Entrada**: `timer_dispensador` (26 bits)
- **Operação**: Incremento de contador para medir 1 segundo
- **Circuito Sintetizado**: Somador binário de 26 bits (conta até 50.000.000)

---

### 1.2 Contador de Dúzias (`contador_duzias.v`)

#### ✅ **Operação: ADIÇÃO (+1) - Incremento de Dúzia**

**Localização:** Linhas 51-53

```verilog
else if (pulso_incrementar) begin
    // OPERAÇÃO ARITMÉTICA: ADIÇÃO
    contador_valor <= contador_valor + 1;
end
```

**Descrição:**
- **Operador Aritmético**: `+` (somador de 7 bits)
- **Entrada**: `contador_valor` (7 bits, range 0-99)
- **Operação**: Adiciona 1 unidade (1 dúzia processada)
- **Circuito Sintetizado**: Somador binário de 7 bits
- **Reset Automático**: Quando atinge 10, volta a 0 (linhas 47-48)
- **Trigger**: Pulso de `incrementar` (vem da FSM Mestre quando garrafa passa pelo sensor final)

**Exemplo de Execução:**
```
Valor Atual: 3 (0000011)
Operação:    3 + 1
Resultado:   4 (0000100)

Valor Atual: 9 (0001001)
Operação:    9 + 1
Resultado:   10 (0001010)
Em seguida:  Reset automático -> 0
```

---

## 🎨 2. DECODIFICADOR BCD PARA DISPLAYS DE 7 SEGMENTOS

### 2.1 Arquitetura do Decodificador (`decodificador_display.v`)

O módulo implementa a conversão completa de um valor binário (0-99) para dois displays de 7 segmentos.

#### **Etapa 1: Extração de Dezena e Unidade (DIVISÃO e MÓDULO)**

**Localização:** Linhas 17-19

```verilog
wire [3:0] dezena;
wire [3:0] unidade;

// OPERAÇÕES ARITMÉTICAS: DIVISÃO e MÓDULO
assign dezena = valor / 10;      // Divisor inteiro
assign unidade = valor % 10;     // Resto da divisão (módulo)
```

**Descrição:**
- **Operador Aritmético 1**: `/` (divisor inteiro de 7 bits por constante)
- **Operador Aritmético 2**: `%` (módulo de 7 bits por constante)
- **Entrada**: `valor` (7 bits, range 0-99)
- **Saídas**: `dezena` (4 bits, 0-9) e `unidade` (4 bits, 0-9)
- **Circuito Sintetizado**: 
  - Divisor otimizado por constante 10 (usa shifts e subtrações)
  - Módulo 10 (usa divisor + multiplicação + subtração)

**Exemplo de Execução:**
```
Entrada: 47 (0101111)

Cálculo Dezena:
47 / 10 = 4 (0100)

Cálculo Unidade:
47 % 10 = 7 (0111)

Resultado: 
dezena = 4, unidade = 7
Display mostra: "47"
```

**Exemplo Complexo:**
```
Entrada: 99 (1100011)

Cálculo Dezena:
99 / 10 = 9 (1001)

Cálculo Unidade:
99 % 10 = 9 (1001)

Resultado:
Display mostra: "99"
```

#### **Etapa 2: Decodificação BCD para 7 Segmentos**

**Localização:** Linhas 22-53

```verilog
// Decodificação para HEX0 (unidade)
always @(*) begin
    case (unidade)
        4'd0: hex0 = 7'b1000000; // 0
        4'd1: hex0 = 7'b1111001; // 1
        4'd2: hex0 = 7'b0100100; // 2
        // ... (continua para todos os dígitos 0-9)
    endcase
end

// Decodificação para HEX1 (dezena)
always @(*) begin
    case (dezena)
        4'd0: hex1 = 7'b1000000; // 0
        4'd1: hex1 = 7'b1111001; // 1
        // ... (continua para todos os dígitos 0-9)
    endcase
end
```

**Descrição:**
- **Tipo**: Lógica combinacional (tabela de verdade)
- **Entrada**: Valor BCD de 4 bits (0-9)
- **Saída**: 7 bits para os segmentos do display (ativo baixo)
- **Circuito Sintetizado**: ROM ou multiplexador 10:1 de 7 bits

**Mapeamento dos Segmentos:**

```
    a
   ---
f |   | b
  | g |
   ---
e |   | c
  |   |
   ---
    d

Bit: [6] [5] [4] [3] [2] [1] [0]
Seg:  g   f   e   d   c   b   a
```

**Exemplo: Exibir o Dígito "5"**

```verilog
4'd5: hex0 = 7'b0010010;
```

Decomposição:
```
Bits: g f e d c b a
      0 0 1 0 0 1 0

Segmentos Ligados (0 = ON):
- a: ON  (topo)
- f: ON  (esquerda superior)
- g: ON  (meio)
- c: ON  (direita inferior)
- d: ON  (base)

Resultado Visual:
   ---
  |
   ---
      |
   ---
```

---

### 2.2 Mapeamento Completo dos Displays no Sistema

#### **Display HEX3-HEX2: Contador de Dúzias**

```verilog
// No módulo projeto_vinho_top.v (linhas 255-259)
decodificador_display dec_duzias (
    .valor(contador_duzias),    // Entrada: 0-99
    .hex1(HEX3),                // Saída: Dezena das dúzias
    .hex0(HEX2)                 // Saída: Unidade das dúzias
);
```

**Exemplo de Funcionamento:**
```
contador_duzias = 7 garrafas processadas

Entrada decodificador: 7 (0000111)
Divisão:  7 / 10 = 0 (dezena)
Módulo:   7 % 10 = 7 (unidade)

HEX3 exibe: "0"
HEX2 exibe: "7"
Resultado visual: "07"
```

#### **Display HEX1-HEX0: Contador de Rolhas**

```verilog
// No módulo projeto_vinho_top.v (linhas 249-253)
decodificador_display dec_rolhas (
    .valor(contador_rolhas),    // Entrada: 0-99
    .hex1(HEX1),                // Saída: Dezena das rolhas
    .hex0(HEX0)                 // Saída: Unidade das rolhas
);
```

**Exemplo de Funcionamento:**
```
contador_rolhas = 20 rolhas disponíveis

Entrada decodificador: 20 (0010100)
Divisão:  20 / 10 = 2 (dezena)
Módulo:   20 % 10 = 0 (unidade)

HEX1 exibe: "2"
HEX0 exibe: "0"
Resultado visual: "20"
```

---

## 🔬 3. ANÁLISE DE SÍNTESE (Hardware Gerado)

### 3.1 Recursos Utilizados (Estimativa)

| Módulo | LUTs | Registradores | DSP Blocks | Memória |
|--------|------|---------------|------------|---------|
| `contador_rolhas` | ~120 | 35 (7 + 26 + 2) | 0 | 0 |
| `contador_duzias` | ~30 | 9 (7 + 2) | 0 | 0 |
| `decodificador_display` (x2) | ~80 | 0 | 0 | 0 |
| **TOTAL Datapath** | **~310** | **44** | **0** | **0** |

### 3.2 Circuitos Aritméticos Sintetizados

#### **Somador de 7 bits (+1)**
- **Circuito**: Ripple-Carry Adder ou Carry-Lookahead Adder
- **Atraso**: ~7 níveis de lógica (worst case)
- **Uso**: Incremento de contadores

#### **Somador de 7 bits (+15)**
- **Circuito**: Somador com uma entrada hardwired à constante 15
- **Otimização**: Quartus otimiza removendo LUTs desnecessárias
- **Atraso**: ~7 níveis de lógica

#### **Subtrator de 7 bits (-1)**
- **Circuito**: Somador com entrada invertida + carry-in = 1
- **Implementação**: `A + (~1) + 1 = A - 1`
- **Atraso**: ~7 níveis de lógica

#### **Divisor por 10 (valor / 10)**
- **Circuito**: Implementado via shifts e subtrações sucessivas
- **Otimização**: Quartus pode usar algoritmo de multiplicação por recíproco
- **Método Aproximado**: `(valor * 13) >> 7` (aproximação de /10)

#### **Módulo 10 (valor % 10)**
- **Circuito**: `valor - (valor / 10) * 10`
- **Implementação**: Divisor + Multiplicador por 10 + Subtrator
- **Otimização**: Multiplicação por 10 = (valor << 3) + (valor << 1)

---

## 🎯 4. VERIFICAÇÃO DOS REQUISITOS

### ✅ **Requisito 1: Lógica Aritmética nos Contadores**

| Operação | Módulo | Linha | Operador | Status |
|----------|--------|-------|----------|--------|
| Subtração (-1) | `contador_rolhas.v` | 69 | `-` | ✅ Implementado |
| Adição (+1) manual | `contador_rolhas.v` | 65 | `+` | ✅ Implementado |
| Adição (+15) automática | `contador_rolhas.v` | 112 | `+` | ✅ Implementado |
| Adição (+1) dúzias | `contador_duzias.v` | 52 | `+` | ✅ Implementado |
| Incremento timer | `contador_rolhas.v` | 106 | `+` | ✅ Implementado |

### ✅ **Requisito 2: Decodificador BCD para Displays**

| Componente | Módulo | Linhas | Status |
|------------|--------|--------|--------|
| Extração Dezena (/) | `decodificador_display.v` | 18 | ✅ Implementado |
| Extração Unidade (%) | `decodificador_display.v` | 19 | ✅ Implementado |
| Tabela BCD -> 7seg (HEX0) | `decodificador_display.v` | 22-36 | ✅ Implementado |
| Tabela BCD -> 7seg (HEX1) | `decodificador_display.v` | 39-53 | ✅ Implementado |
| Instância para Rolhas | `projeto_vinho_top.v` | 249-253 | ✅ Implementado |
| Instância para Dúzias | `projeto_vinho_top.v` | 255-259 | ✅ Implementado |

---

## 📝 5. NOTA SOBRE MULTIPLEXAÇÃO

### ❓ Por que NÃO há Multiplexação?

O usuário mencionou multiplexação, mas **na placa DE10-Lite, cada display de 7 segmentos tem seus próprios pinos dedicados**. Não é um display multiplexado comum (como em alguns sistemas embarcados onde 4 displays compartilham os mesmos 7 pinos e são ativados por varredura).

#### **Arquitetura da DE10-Lite:**

```
FPGA MAX10
├── HEX0[6:0] ──> 7 pinos exclusivos ──> Display 0
├── HEX1[6:0] ──> 7 pinos exclusivos ──> Display 1
├── HEX2[6:0] ──> 7 pinos exclusivos ──> Display 2
├── HEX3[6:0] ──> 7 pinos exclusivos ──> Display 3
├── HEX4[6:0] ──> 7 pinos exclusivos ──> Display 4
└── HEX5[6:0] ──> 7 pinos exclusivos ──> Display 5
```

**Total de pinos para displays:** 6 displays × 7 segmentos = **42 pinos dedicados**

Portanto, **não há necessidade de multiplexação**. Todos os displays ficam ligados simultaneamente de forma contínua.

---

## 🧪 6. TESTES RECOMENDADOS PARA VALIDAÇÃO ARITMÉTICA

### Teste 1: Reposição Automática (+15)

```
1. Reset o sistema
2. Use SW[7] para decrementar até 5 rolhas
3. Observe LEDR[5] acender (dispensador)
4. Após 1s, HEX1-HEX0 deve mostrar "20"
   Verificação: 5 + 15 = 20 ✅
```

### Teste 2: Saturação no Máximo

```
1. Use SW[7] para incrementar até 94 rolhas
2. Espere reposição automática (94 -> 89 -> 84... -> 5)
3. Quando atingir 5, dispensador adiciona 15
4. Esperado: 5 + 15 = 20 (não 5 + 94 = overflow)
5. Se fosse saturar: 84 + 15 = 99 (máximo) ✅
```

### Teste 3: Contador de Dúzias (+1 e Reset)

```
1. Reset o sistema
2. Processe 9 garrafas (incrementa 9 vezes)
3. HEX3-HEX2 deve mostrar "09"
4. Processe mais 1 garrafa (10ª)
5. HEX3-HEX2 deve mostrar "00" (reset automático) ✅
```

### Teste 4: Displays Simultâneos

```
1. Configure: 47 rolhas, 8 dúzias
2. Verifique visualmente todos os 4 displays:
   - HEX3: "0"
   - HEX2: "8"  } Mostra "08" (dúzias)
   - HEX1: "4"
   - HEX0: "7"  } Mostra "47" (rolhas)
3. Todos devem estar acesos SIMULTANEAMENTE ✅
```

---

## 🎓 7. CONCEITOS PEDAGÓGICOS COBERTOS

### Aritmética Digital
- ✅ Somadores binários (ripple-carry)
- ✅ Subtratores (complemento de 2)
- ✅ Comparadores (>, <, ==)
- ✅ Saturação aritmética (proteção overflow)
- ✅ Detecção de underflow

### Conversão de Dados
- ✅ Binário para BCD (divisão/módulo)
- ✅ BCD para 7 segmentos (tabela de verdade)
- ✅ Decodificadores combinacionais

### Controle e Datapath
- ✅ Separação entre Unidade de Controle (FSMs) e Unidade de Operação (Contadores)
- ✅ Sinais de comando (incrementar, decrementar)
- ✅ Sinais de status (alarme, rolha_vazia)

---

## 📚 CONCLUSÃO

O sistema implementa **corretamente** todos os requisitos de aritmética e decodificação:

1. ✅ **Contadores com lógica aritmética explícita** (+1, -1, +15)
2. ✅ **Decodificador BCD completo** (divisão, módulo, tabela 7-seg)
3. ✅ **Displays independentes** (sem necessidade de multiplexação na DE10-Lite)
4. ✅ **Proteções de overflow/underflow**
5. ✅ **Código sintetizável e otimizado**

A arquitetura está pronta para síntese e programação na placa FPGA DE10-Lite!

---

**Última Atualização:** Novembro 2025

