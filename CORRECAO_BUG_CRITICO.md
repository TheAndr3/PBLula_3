# 🐛 Correção de Bug Crítico - Comunicação FSM Mestre-Esteira

## 📋 Resumo Executivo

**Bug Identificado:** Comunicação ambígua entre `fsm_mestre` e as três instâncias de `fsm_esteira`  
**Severidade:** 🔴 **CRÍTICA** - Sistema não funciona corretamente  
**Status:** ✅ **CORRIGIDO**  
**Arquivos Modificados:** `fsm_mestre.v`, `projeto_vinho_top.v`

---

## 🔍 Análise do Bug

### O Problema

#### Antes da Correção (INCORRETO)

```verilog
// fsm_mestre.v - Interface ANTIGA (INCORRETA)
output reg cmd_mover_esteira,            // ❌ UM único comando
input wire esteira_concluida,            // ❌ UM único sinal de conclusão
```

```verilog
// projeto_vinho_top.v - Conexões ANTIGAS (INCORRETAS)
wire cmd_mover_esteira;                  // ❌ Um único wire
wire esteira_concluida;                  // ❌ Um único wire

// ❌ TODAS as três instâncias recebem O MESMO comando!
fsm_esteira fsm_esteira_1 (
    .cmd_mover(cmd_mover_esteira),       // ❌ Compartilhado
    .tarefa_concluida(esteira_concluida_1)
);

fsm_esteira fsm_esteira_2 (
    .cmd_mover(cmd_mover_esteira),       // ❌ Compartilhado
    .tarefa_concluida(esteira_concluida_2)
);

fsm_esteira fsm_esteira_3 (
    .cmd_mover(cmd_mover_esteira),       // ❌ Compartilhado
    .tarefa_concluida(esteira_concluida_3)
);

// ❌ Combina todos os sinais de conclusão
assign esteira_concluida = esteira_concluida_1 | 
                           esteira_concluida_2 | 
                           esteira_concluida_3;
```

### Consequências do Bug

#### Cenário de Falha 1: Sensor CQ ativo prematuramente

```
Situação:
1. FSM Mestre quer mover para ENCHIMENTO
2. Ativa cmd_mover_esteira = 1
3. SW[2] (Sensor CQ) está acidentalmente ativo

Comportamento INCORRETO:
- fsm_esteira_1 recebe comando ✓ (correto)
- fsm_esteira_2 TAMBÉM recebe comando ✗ (erro!)
- fsm_esteira_3 TAMBÉM recebe comando ✗ (erro!)

Se SW[2] estiver ativo:
- fsm_esteira_2 envia esteira_concluida_2 = 1
- esteira_concluida = 1 (via OR lógico)
- FSM Mestre pensa que chegou no ENCHIMENTO
- MAS NA VERDADE o sensor CQ foi detectado!
- Sistema pula etapas ❌ COMPORTAMENTO INCORRETO
```

#### Cenário de Falha 2: Múltiplas FSMs competindo

```
Situação:
1. FSM Mestre quer mover para CQ (etapa 2)
2. Ativa cmd_mover_esteira = 1
3. SW[0] e SW[4] estão ambos ativos

Comportamento INCORRETO:
- Três FSMs começam a processar simultaneamente
- Qualquer sensor ativo vai gerar esteira_concluida
- FSM Mestre não sabe QUAL etapa realmente concluiu
- Sistema fica em estado inconsistente ❌
```

---

## ✅ Solução Implementada

### Interface Corrigida

#### Depois da Correção (CORRETO)

```verilog
// fsm_mestre.v - Interface NOVA (CORRETA)
output reg cmd_mover_para_enchimento,    // ✅ Comando específico para Etapa 1
output reg cmd_mover_para_cq,            // ✅ Comando específico para Etapa 2
output reg cmd_mover_para_final,         // ✅ Comando específico para Etapa 3

input wire esteira_concluida_enchimento, // ✅ Conclusão específica Etapa 1
input wire esteira_concluida_cq,         // ✅ Conclusão específica Etapa 2
input wire esteira_concluida_final,      // ✅ Conclusão específica Etapa 3
```

### Conexões Corrigidas

```verilog
// projeto_vinho_top.v - Conexões NOVAS (CORRETAS)

// ✅ Três wires distintos para comandos
wire cmd_mover_para_enchimento;
wire cmd_mover_para_cq;
wire cmd_mover_para_final;

// ✅ Três wires distintos para conclusões
wire esteira_concluida_enchimento;
wire esteira_concluida_cq;
wire esteira_concluida_final;

// ✅ Cada FSM conectada ao seu comando específico
fsm_esteira fsm_esteira_1 (
    .cmd_mover(cmd_mover_para_enchimento),      // ✅ Específico
    .tarefa_concluida(esteira_concluida_enchimento) // ✅ Específico
);

fsm_esteira fsm_esteira_2 (
    .cmd_mover(cmd_mover_para_cq),              // ✅ Específico
    .tarefa_concluida(esteira_concluida_cq)     // ✅ Específico
);

fsm_esteira fsm_esteira_3 (
    .cmd_mover(cmd_mover_para_final),           // ✅ Específico
    .tarefa_concluida(esteira_concluida_final)  // ✅ Específico
);

// ✅ Motor combina as três saídas (isso está CORRETO)
assign motor_ativo = motor_ativo_1 | motor_ativo_2 | motor_ativo_3;
```

---

## 🔧 Modificações Detalhadas

### 1. Modificações em `fsm_mestre.v`

#### 1.1 Interface do Módulo (Linhas 9-35)

```diff
module fsm_mestre (
    input wire clk,
    input wire reset,
    input wire start,
    input wire alarme_rolha,
    input wire sensor_final,
    
-   // Sinais das FSMs escravas
-   input wire esteira_concluida,
+   // Sinais das FSMs escravas (DISTINTOS)
+   input wire esteira_concluida_enchimento,
+   input wire esteira_concluida_cq,
+   input wire esteira_concluida_final,
    input wire enchimento_concluido,
    input wire vedacao_concluida,
    input wire cq_concluida,
    input wire garrafa_aprovada,
    
-   // Comandos para FSMs escravas
-   output reg cmd_mover_esteira,
+   // Comandos para FSMs escravas (DISTINTOS)
+   output reg cmd_mover_para_enchimento,
+   output reg cmd_mover_para_cq,
+   output reg cmd_mover_para_final,
    output reg cmd_encher,
    output reg cmd_vedar,
    output reg cmd_verificar_cq,
    
    output reg incrementar_duzia
);
```

#### 1.2 Transições de Estado (Linhas 111-205)

```diff
AGUARDA_ESTEIRA_1: begin
-   if (esteira_concluida) begin
+   if (esteira_concluida_enchimento) begin
        estado_atual <= ENCHENDO;
    end
end

AGUARDA_ESTEIRA_2: begin
-   if (esteira_concluida) begin
+   if (esteira_concluida_cq) begin
        estado_atual <= VERIFICANDO_CQ;
    end
end

AGUARDA_ESTEIRA_3: begin
-   if (esteira_concluida) begin
+   if (esteira_concluida_final) begin
        estado_atual <= CONTANDO_FINAL;
    end
end
```

#### 1.3 Lógica de Saída Moore (Linhas 229-283)

```diff
always @(posedge clk or posedge reset) begin
    if (reset) begin
-       cmd_mover_esteira <= 1'b0;
+       cmd_mover_para_enchimento <= 1'b0;
+       cmd_mover_para_cq <= 1'b0;
+       cmd_mover_para_final <= 1'b0;
        // ... outros comandos
    end else begin
-       cmd_mover_esteira <= 1'b0;
+       cmd_mover_para_enchimento <= 1'b0;
+       cmd_mover_para_cq <= 1'b0;
+       cmd_mover_para_final <= 1'b0;
        
        case (estado_atual)
            MOVER_PARA_ENCHIMENTO, AGUARDA_ESTEIRA_1: begin
-               cmd_mover_esteira <= 1'b1;
+               cmd_mover_para_enchimento <= 1'b1;
            end
            
            MOVER_PARA_CQ, AGUARDA_ESTEIRA_2: begin
-               cmd_mover_esteira <= 1'b1;
+               cmd_mover_para_cq <= 1'b1;
            end
            
            MOVER_PARA_FINAL, AGUARDA_ESTEIRA_3: begin
-               cmd_mover_esteira <= 1'b1;
+               cmd_mover_para_final <= 1'b1;
            end
        endcase
    end
end
```

---

### 2. Modificações em `projeto_vinho_top.v`

#### 2.1 Declaração de Wires (Linhas 80-117)

```diff
-// Sinais da FSM Mestre
-wire cmd_mover_esteira;
+// Sinais da FSM Mestre (COMANDOS DISTINTOS)
+wire cmd_mover_para_enchimento;
+wire cmd_mover_para_cq;
+wire cmd_mover_para_final;

-// Sinais das FSMs Escravas
-wire esteira_concluida;
 wire enchimento_concluido;
 // ... outros sinais

-// Movimento 1: Até enchimento (sensor SW0)
 wire motor_ativo_1;
-wire esteira_concluida_1;
+wire esteira_concluida_enchimento;

-// Movimento 2: Até CQ (sensor SW2)
 wire motor_ativo_2;
-wire esteira_concluida_2;
+wire esteira_concluida_cq;

-// Movimento 3: Até final (sensor SW4)
 wire motor_ativo_3;
-wire esteira_concluida_3;
+wire esteira_concluida_final;

+// Combinar os motores (mantém OR lógico - CORRETO)
 assign motor_ativo = motor_ativo_1 | motor_ativo_2 | motor_ativo_3;

-// ❌ REMOVIDO: Combinar sinais de conclusão (isso causava o bug!)
-assign esteira_concluida = esteira_concluida_1 | 
-                           esteira_concluida_2 | 
-                           esteira_concluida_3;
```

#### 2.2 Instanciação da FSM Mestre (Linhas 136-162)

```diff
fsm_mestre fsm_mestre_inst (
    .clk(clk),
    .reset(reset),
    .start(pulso_start),
    .alarme_rolha(alarme_rolha_vazia),
    .sensor_final(sensor_final),
    
-   // Sinais das FSMs escravas
-   .esteira_concluida(esteira_concluida),
+   // Sinais das FSMs escravas (DISTINTOS)
+   .esteira_concluida_enchimento(esteira_concluida_enchimento),
+   .esteira_concluida_cq(esteira_concluida_cq),
+   .esteira_concluida_final(esteira_concluida_final),
    .enchimento_concluido(enchimento_concluido),
    .vedacao_concluida(vedacao_concluida),
    .cq_concluida(cq_concluida),
    .garrafa_aprovada(garrafa_aprovada),
    
-   // Comandos para FSMs escravas
-   .cmd_mover_esteira(cmd_mover_esteira),
+   // Comandos para FSMs escravas (DISTINTOS)
+   .cmd_mover_para_enchimento(cmd_mover_para_enchimento),
+   .cmd_mover_para_cq(cmd_mover_para_cq),
+   .cmd_mover_para_final(cmd_mover_para_final),
    .cmd_encher(cmd_encher),
    .cmd_vedar(cmd_vedar),
    .cmd_verificar_cq(cmd_verificar_cq),
    
    .incrementar_duzia(incrementar_duzia)
);
```

#### 2.3 Instâncias das FSMs Esteira (Linhas 167-201)

```diff
// FSM Esteira 1 (Enchimento)
fsm_esteira fsm_esteira_1 (
    .clk(clk),
    .reset(reset),
-   .cmd_mover(cmd_mover_esteira),
+   .cmd_mover(cmd_mover_para_enchimento),
    .sensor_destino(sensor_posicao_enchimento),
    .alarme_rolha(alarme_rolha_vazia),
    .motor_ativo(motor_ativo_1),
-   .tarefa_concluida(esteira_concluida_1)
+   .tarefa_concluida(esteira_concluida_enchimento)
);

// FSM Esteira 2 (CQ)
fsm_esteira fsm_esteira_2 (
    .clk(clk),
    .reset(reset),
-   .cmd_mover(cmd_mover_esteira),
+   .cmd_mover(cmd_mover_para_cq),
    .sensor_destino(sensor_posicao_cq),
    .alarme_rolha(alarme_rolha_vazia),
    .motor_ativo(motor_ativo_2),
-   .tarefa_concluida(esteira_concluida_2)
+   .tarefa_concluida(esteira_concluida_cq)
);

// FSM Esteira 3 (Final)
fsm_esteira fsm_esteira_3 (
    .clk(clk),
    .reset(reset),
-   .cmd_mover(cmd_mover_esteira),
+   .cmd_mover(cmd_mover_para_final),
    .sensor_destino(sensor_final),
    .alarme_rolha(alarme_rolha_vazia),
    .motor_ativo(motor_ativo_3),
-   .tarefa_concluida(esteira_concluida_3)
+   .tarefa_concluida(esteira_concluida_final)
);
```

---

## ✅ Validação da Correção

### Cenário 1: Movimento para Enchimento (Etapa 1)

```
FSM Mestre: estado = MOVER_PARA_ENCHIMENTO
Saída: cmd_mover_para_enchimento = 1
       cmd_mover_para_cq = 0        ✅
       cmd_mover_para_final = 0      ✅

Apenas fsm_esteira_1 é ativada ✅
Apenas esteira_concluida_enchimento pode sinalizar conclusão ✅

Mesmo se SW[2] ou SW[4] estiverem ativos:
- fsm_esteira_2 permanece em IDLE (cmd = 0) ✅
- fsm_esteira_3 permanece em IDLE (cmd = 0) ✅
```

### Cenário 2: Movimento para CQ (Etapa 2)

```
FSM Mestre: estado = MOVER_PARA_CQ
Saída: cmd_mover_para_enchimento = 0   ✅
       cmd_mover_para_cq = 1
       cmd_mover_para_final = 0         ✅

Apenas fsm_esteira_2 é ativada ✅
Apenas esteira_concluida_cq pode sinalizar conclusão ✅

Sensores SW[0] e SW[4] são ignorados ✅
```

### Cenário 3: Movimento para Final (Etapa 3)

```
FSM Mestre: estado = MOVER_PARA_FINAL
Saída: cmd_mover_para_enchimento = 0   ✅
       cmd_mover_para_cq = 0            ✅
       cmd_mover_para_final = 1

Apenas fsm_esteira_3 é ativada ✅
Apenas esteira_concluida_final pode sinalizar conclusão ✅

Sensores SW[0] e SW[2] são ignorados ✅
```

---

## 📊 Impacto da Correção

### Antes (INCORRETO)
```
┌─────────────────────────────────────────┐
│  FSM Mestre                             │
│                                         │
│  cmd_mover_esteira ──┬─────────────┐   │
│                      │             │   │
│                      ▼             ▼   │
│                 Esteira 1    Esteira 2  │
│                      │             │   │
│  esteira_concluida ◄─┴─────────────┘   │
│         ▲                               │
│         └───── Esteira 3                │
│                                         │
│  ❌ AMBÍGUO: Qual esteira respondeu?   │
└─────────────────────────────────────────┘
```

### Depois (CORRETO)
```
┌─────────────────────────────────────────┐
│  FSM Mestre                             │
│                                         │
│  cmd_mover_para_enchimento ──► Esteira 1│
│  esteira_concluida_enchimento ◄─────────│
│                                         │
│  cmd_mover_para_cq ──────────► Esteira 2│
│  esteira_concluida_cq ◄─────────────────│
│                                         │
│  cmd_mover_para_final ────────► Esteira 3│
│  esteira_concluida_final ◄──────────────│
│                                         │
│  ✅ CLARO: Comunicação ponto-a-ponto   │
└─────────────────────────────────────────┘
```

---

## 🧪 Testes de Validação

### Teste 1: Sequência Completa
```
1. START → cmd_mover_para_enchimento = 1
2. SW[0] ativo → esteira_concluida_enchimento = 1
3. Enchimento → cmd_encher = 1
4. SW[1] ativo → enchimento_concluido = 1
5. Vedação → cmd_vedar = 1
6. Após 0.5s → vedacao_concluida = 1
7. Movimento CQ → cmd_mover_para_cq = 1
8. SW[2] ativo → esteira_concluida_cq = 1
9. CQ → cmd_verificar_cq = 1
10. SW[3]=1 → garrafa_aprovada = 1
11. Movimento Final → cmd_mover_para_final = 1
12. SW[4] ativo → esteira_concluida_final = 1
13. Contagem → incrementar_duzia = 1

✅ PASSA - Sequência completa sem interferências
```

### Teste 2: Sensores Espúrios
```
Configuração: SW[0], SW[2], SW[4] todos ativos
Ação: Pressionar START

Comportamento:
- Apenas cmd_mover_para_enchimento é ativado
- Apenas fsm_esteira_1 responde
- SW[2] e SW[4] são ignorados
- Sistema avança corretamente

✅ PASSA - Imune a sensores espúrios
```

### Teste 3: Transições Rápidas
```
Ação: Ligar/desligar SW[0], SW[2], SW[4] rapidamente

Comportamento:
- Cada FSM Esteira só responde ao seu comando específico
- Não há interferência cruzada
- Estado sempre consistente

✅ PASSA - Transições rápidas corretas
```

---

## 📝 Resumo das Mudanças

| Aspecto | Antes | Depois | Status |
|---------|-------|--------|--------|
| **Comandos** | 1 sinal compartilhado | 3 sinais distintos | ✅ |
| **Conclusões** | 1 sinal combinado (OR) | 3 sinais distintos | ✅ |
| **Ambiguidade** | Alta (não sabe qual FSM) | Zero (comando direto) | ✅ |
| **Interferência** | Possível (todas FSMs ativas) | Impossível (FSM específica) | ✅ |
| **Debugging** | Difícil (sinais misturados) | Fácil (sinais claros) | ✅ |
| **Manutenibilidade** | Baixa | Alta | ✅ |

---

## 🎓 Lições Aprendidas

### 1. **Princípio da Comunicação Ponto-a-Ponto**
   - Sempre use sinais distintos para módulos distintos
   - Evite multiplexar sinais de controle críticos
   - Comunicação ambígua = bugs difíceis de detectar

### 2. **Arquitetura Mestre-Escravo Correta**
   - Mestre deve ter controle preciso de QUAL escravo ativar
   - Escravos devem ter canais de retorno distintos
   - Sinais compartilhados (como `motor_ativo`) só para saídas físicas finais

### 3. **Debugging Proativo**
   - Sinais bem nomeados facilitam debugging
   - `cmd_mover_para_enchimento` é mais claro que `cmd_mover_esteira`
   - `esteira_concluida_cq` é mais claro que `esteira_concluida_2`

---

## ✅ Checklist Final

- [x] Interface da `fsm_mestre` corrigida (3 comandos, 3 conclusões)
- [x] Transições de estado usando sinais corretos
- [x] Lógica de saída Moore gerando comandos específicos
- [x] Wires no `top` declarados corretamente
- [x] Instância da `fsm_mestre` conectada corretamente
- [x] 3 instâncias `fsm_esteira` conectadas aos sinais específicos
- [x] Linting sem erros
- [x] Documentação do bug e correção

---

## 🏆 Conclusão

✅ **BUG CRÍTICO CORRIGIDO COM SUCESSO**

O sistema agora possui:
- **Comunicação clara e não-ambígua** entre mestre e escravos
- **Imunidade a sensores espúrios** em outras etapas
- **Sequenciamento correto** do processo
- **Código manutenível** e fácil de debugar

**O projeto está pronto para síntese e testes na FPGA!** 🚀

---

**Data da Correção:** Novembro 2025  
**Arquivos Corrigidos:** `fsm_mestre.v`, `projeto_vinho_top.v`  
**Linhas Modificadas:** ~60 linhas  
**Impacto:** Correção de bug crítico que impedia funcionamento correto

