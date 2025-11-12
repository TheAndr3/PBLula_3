# 🎮 Guia Prático de Uso - Controlador de Linha de Vinhos

## 🍷 Como Rodar o Projeto na Placa DE10-Lite

Este guia fornece instruções passo-a-passo para compilar, programar e testar o projeto na FPGA.

---

## 📋 Pré-Requisitos

### Hardware Necessário
- ✅ Placa FPGA DE10-Lite (Intel MAX 10)
- ✅ Cabo USB (Type A para Mini-B)
- ✅ Computador com Windows/Linux/Mac

### Software Necessário
- ✅ **Intel Quartus Prime Lite** (versão 20.1 ou superior)
  - Download: https://www.intel.com/content/www/us/en/software/programmable/quartus-prime/download.html
  - Tamanho: ~5GB
  - **IMPORTANTE**: Baixe a versão **Lite** (gratuita)

---

## 🚀 PARTE 1: Compilação no Quartus Prime

### Passo 1: Criar Novo Projeto

1. **Abra o Quartus Prime**

2. **File → New Project Wizard**

3. **Página 1 - Diretório do Projeto**
   ```
   Working directory: C:\projects\ula_3
   Project name: projeto_vinho
   Top-level design entity: projeto_vinho_top
   ```
   - Clique **Next**

4. **Página 2 - Project Type**
   - Selecione: **Empty Project**
   - Clique **Next**

5. **Página 3 - Add Files**
   - Clique **Add All** (ou adicione manualmente):
     ```
     ✓ projeto_vinho_top.v
     ✓ fsm_mestre.v
     ✓ fsm_esteira.v
     ✓ fsm_enchimento.v
     ✓ fsm_vedacao.v
     ✓ fsm_cq_descarte.v
     ✓ contador_rolhas.v
     ✓ contador_duzias.v
     ✓ debounce.v
     ✓ decodificador_display.v
     ```
   - Clique **Next**

6. **Página 4 - Family, Device & Board Settings**
   ```
   Family: MAX 10
   Device: 10M50DAF484C7G
   ```
   - Ou use o filtro:
     - Package: FBGA
     - Pin count: 484
   - Clique **Next** → **Next** → **Finish**

---

### Passo 2: Configurar Pin Assignment (CRÍTICO!)

Este é o passo mais importante - conecta os sinais do Verilog aos pinos físicos da placa.

#### Opção A: Usar o Pin Planner (Manual)

1. **Assignments → Pin Planner** (ou `Ctrl+Shift+N`)

2. **Configure os seguintes pinos**:

   | Sinal Verilog | Pino FPGA | Descrição |
   |---------------|-----------|-----------|
   | `CLOCK_50` | PIN_P11 | Clock 50MHz |
   | `KEY[0]` | PIN_B8 | Botão START |
   | `KEY[1]` | PIN_A7 | Botão RESET |
   | `SW[0]` | PIN_C10 | Sensor Enchimento |
   | `SW[1]` | PIN_C11 | Sensor Nível |
   | `SW[2]` | PIN_D12 | Sensor CQ |
   | `SW[3]` | PIN_C12 | Resultado CQ |
   | `SW[4]` | PIN_A12 | Sensor Final |
   | `SW[7]` | PIN_C14 | Adicionar Rolha |
   | `LEDR[0]` | PIN_A8 | Alarme |
   | `LEDR[5]` | PIN_A10 | Dispensador |
   | `LEDR[6]` | PIN_B10 | Descarte |
   | `LEDR[7]` | PIN_D13 | Vedação |
   | `LEDR[8]` | PIN_C13 | Válvula |
   | `LEDR[9]` | PIN_E14 | Motor |
   | `HEX0[0]` | PIN_C14 | Display 0 seg A |
   | `HEX0[1]` | PIN_E15 | Display 0 seg B |
   | `HEX0[2]` | PIN_C15 | Display 0 seg C |
   | `HEX0[3]` | PIN_C16 | Display 0 seg D |
   | `HEX0[4]` | PIN_E16 | Display 0 seg E |
   | `HEX0[5]` | PIN_D17 | Display 0 seg F |
   | `HEX0[6]` | PIN_C17 | Display 0 seg G |
   | `HEX1[0]` | PIN_C18 | Display 1 seg A |
   | `HEX1[1]` | PIN_D18 | Display 1 seg B |
   | `HEX1[2]` | PIN_E18 | Display 1 seg C |
   | `HEX1[3]` | PIN_B16 | Display 1 seg D |
   | `HEX1[4]` | PIN_A17 | Display 1 seg E |
   | `HEX1[5]` | PIN_A18 | Display 1 seg F |
   | `HEX1[6]` | PIN_B17 | Display 1 seg G |
   | `HEX2[0]` | PIN_B20 | Display 2 seg A |
   | `HEX2[1]` | PIN_A20 | Display 2 seg B |
   | `HEX2[2]` | PIN_B19 | Display 2 seg C |
   | `HEX2[3]` | PIN_A21 | Display 2 seg D |
   | `HEX2[4]` | PIN_B21 | Display 2 seg E |
   | `HEX2[5]` | PIN_C22 | Display 2 seg F |
   | `HEX2[6]` | PIN_B22 | Display 2 seg G |
   | `HEX3[0]` | PIN_F21 | Display 3 seg A |
   | `HEX3[1]` | PIN_E22 | Display 3 seg B |
   | `HEX3[2]` | PIN_E21 | Display 3 seg C |
   | `HEX3[3]` | PIN_C19 | Display 3 seg D |
   | `HEX3[4]` | PIN_C20 | Display 3 seg E |
   | `HEX3[5]` | PIN_D19 | Display 3 seg F |
   | `HEX3[6]` | PIN_E17 | Display 3 seg G |

3. **Salve**: File → Save (ou `Ctrl+S`)

#### Opção B: Usar Arquivo QSF (Automático)

1. Crie um arquivo `projeto_vinho.qsf` na pasta do projeto

2. Cole o conteúdo de pin assignment (fornecido separadamente)

3. Reabra o projeto no Quartus

---

### Passo 3: Compilar o Projeto

1. **Processing → Start Compilation** (ou pressione `Ctrl+L`)

2. **Aguarde a compilação** (pode levar 3-5 minutos)

3. **Verifique os resultados**:
   ```
   ✅ Analysis & Synthesis: Successful
   ✅ Fitter: Successful
   ✅ Assembler: Successful
   ✅ Timing Analyzer: Successful
   ```

4. **Verifique o relatório**:
   - Logic elements used: ~450 / 50,000 (< 1%)
   - Pins used: 46
   - Timing: Todos os caminhos devem atender ao requisito

5. **Se houver ERROS**:
   - Veja seção "Troubleshooting" abaixo
   - Verifique se todos os arquivos `.v` foram adicionados
   - Verifique se `projeto_vinho_top` está definido como top-level

---

## 🔌 PARTE 2: Programar a FPGA

### Passo 1: Conectar a Placa

1. **Conecte o cabo USB** da placa ao computador

2. **Ligue a placa**:
   - Use a fonte externa (9V) OU
   - Use alimentação via USB (se suportado)

3. **Verifique a conexão**:
   - Windows: Device Manager → USB Blaster
   - Linux: `lsusb | grep Altera`

---

### Passo 2: Abrir o Programmer

1. **Tools → Programmer** (ou `Ctrl+Alt+P`)

2. **Hardware Setup**:
   - Clique em **Hardware Setup...**
   - Selecione: **USB-Blaster [USB-0]**
   - Clique **Close**

3. **Adicionar arquivo de programação**:
   - Se já houver um arquivo `.sof` listado, pule para o próximo passo
   - Se não:
     - Clique **Add File...**
     - Navegue até: `output_files/projeto_vinho.sof`
     - Clique **Open**

4. **Configure o Device**:
   - ✅ Marque a checkbox **Program/Configure**
   - Device deve mostrar: `10M50DAF484`

---

### Passo 3: Programar!

1. **Clique no botão "Start"** (ou pressione `Ctrl+P`)

2. **Aguarde a programação** (10-30 segundos)
   ```
   Progress: 100% (Successful)
   ```

3. **Verifique**:
   - A placa deve estar programada
   - LEDs podem acender aleatoriamente (é normal)

---

## 🧪 PARTE 3: Testar o Sistema

### Preparação Inicial

1. **Reset do sistema**:
   - Pressione `KEY[1]` (Reset)
   - **Observe**: HEX1-HEX0 deve mostrar "20" (rolhas iniciais)
   - **Observe**: HEX3-HEX2 deve mostrar "00" (zero dúzias)
   - **Observe**: Todos os LEDs devem estar apagados

2. **Estado inicial**:
   - Todas as chaves `SW[0-9]` devem estar em **posição baixa** (0)

---

### 🎯 Teste 1: Ciclo Completo (Cenário Ideal)

Este teste simula o processamento de UMA garrafa do início ao fim.

#### Etapa 1: Iniciar o Processo
```
Ação: Pressione KEY[0] (START)

✅ Esperado:
- LEDR[9] (Motor) acende
- Sistema está movendo a garrafa para enchimento
```

#### Etapa 2: Garrafa Chega no Enchimento
```
Ação: Ligue SW[0] (Sensor Enchimento)

✅ Esperado:
- LEDR[9] apaga IMEDIATAMENTE (parada MEALY!)
- LEDR[8] (Válvula) acende
- Sistema está enchendo a garrafa
```

#### Etapa 3: Garrafa Fica Cheia
```
Ação: Ligue SW[1] (Sensor Nível)

✅ Esperado:
- LEDR[8] apaga
- LEDR[7] (Vedação) acende por ~0.5 segundos
- HEX1-HEX0 muda de "20" → "19" (decremento)
```

#### Etapa 4: Movimento para Controle de Qualidade
```
Ação: Aguarde vedação terminar (~0.5s)

✅ Esperado:
- LEDR[7] apaga
- LEDR[9] (Motor) acende novamente
- Sistema está movendo para CQ

Ação: Ligue SW[2] (Sensor CQ)

✅ Esperado:
- LEDR[9] apaga
- Sistema aguarda verificação de qualidade
```

#### Etapa 5: Aprovar a Garrafa
```
Ação: Ligue SW[3] (Resultado CQ = Aprovado)

✅ Esperado:
- Sistema aprova garrafa
- LEDR[9] (Motor) acende novamente
- Sistema está movendo para o final
```

#### Etapa 6: Contagem Final
```
Ação: Ligue SW[4] (Sensor Final)

✅ Esperado:
- LEDR[9] apaga
- HEX3-HEX2 muda de "00" → "01" (uma dúzia processada!)
- Sistema volta ao estado IDLE

💡 Sucesso! Você processou uma garrafa completa!
```

#### Limpeza
```
Ação: Desligue TODOS os switches (SW[0-4])
Resultado: Sistema pronto para próximo ciclo
```

---

### 🎯 Teste 2: Reposição Automática de Rolhas

Simula o sistema atingindo 5 rolhas e acionando o dispensador automático.

```
Situação Inicial: HEX1-HEX0 mostra "20"

Passo 1: Processar 15 garrafas
   - Repita o Teste 1 quinze vezes
   - OU use SW[7] para decrementar manualmente
   
Passo 2: Observe quando chegar a "05"
   ✅ LEDR[5] (Dispensador) acende por 1 segundo
   ✅ Após 1s: HEX1-HEX0 muda "05" → "20" (+15 rolhas!)
   
💡 Sucesso! Reposição automática funcionou!
```

---

### 🎯 Teste 3: Alarme de Falta de Rolha

Simula o sistema ficando sem rolhas.

```
Passo 1: Reduzir para zero rolhas
   Opção A: Processar 20 garrafas (teste 1 × 20)
   Opção B: Usar método rápido (veja abaixo)
   
Passo 2: Quando HEX1-HEX0 = "00"
   ✅ LEDR[0] (Alarme) acende
   ✅ Sistema não aceita mais START
   
Passo 3: Reposição manual
   Ação: Ligue e desligue SW[7] várias vezes
   ✅ HEX1-HEX0 incrementa: "00" → "01" → "02" ...
   ✅ Quando > 0: LEDR[0] apaga
   ✅ Sistema volta a funcionar

💡 Sucesso! Sistema protegido contra falta de rolhas!
```

---

### 🎯 Teste 4: Descarte (CQ Reprovado)

Simula uma garrafa sendo reprovada no controle de qualidade.

```
Passo 1-3: Igual ao Teste 1 (até chegar no CQ)
   - START → SW[0] → SW[1] → Aguarda vedação → SW[2]

Passo 4: Reprovar a garrafa
   Ação: MANTENHA SW[3] DESLIGADO (0 = Reprovado)
   ✅ LEDR[6] (Descarte) acende por ~0.5s
   ✅ Sistema volta ao IDLE
   ✅ HEX3-HEX2 NÃO incrementa (garrafa não foi contada!)
   
💡 Sucesso! Garrafas reprovadas são descartadas!
```

---

### 🎯 Teste 5: Reset Automático de Dúzias

Simula o contador de dúzias atingindo 10 e resetando.

```
Passo 1: Processar 9 garrafas aprovadas
   - Repita Teste 1 nove vezes
   - HEX3-HEX2 deve mostrar "09"
   
Passo 2: Processar a 10ª garrafa
   - Complete mais um ciclo (Teste 1)
   - HEX3-HEX2 mostra "10" momentaneamente
   - ✅ Imediatamente reseta para "00"
   
💡 Sucesso! Reset automático em 10 dúzias!
```

---

## 🎬 Demonstração Rápida (1 Minuto)

Para impressionar rapidamente:

```
1. Reset: KEY[1]
   → Displays: "00" e "20"

2. START: KEY[0]
   → LEDR[9] acende

3. Sequência rápida:
   SW[0] ON  → LEDR[9] apaga, LEDR[8] acende
   SW[1] ON  → LEDR[8] apaga, LEDR[7] pisca
   SW[2] ON  → LEDR[9] acende de novo
   SW[3] ON  → Sistema aprova
   SW[4] ON  → LEDR[9] apaga
   
4. Resultado:
   → Rolhas: "20" → "19"
   → Dúzias: "00" → "01"
   
5. Desligar todos os switches
   → Sistema pronto para novo ciclo

✨ SUCESSO! Sistema funcionando perfeitamente!
```

---

## 🔧 Troubleshooting

### Problema 1: Quartus não compila

**Erro**: "Error: Can't resolve multiple constant drivers"
```
Solução:
1. Certifique-se de usar o contador_rolhas.v CORRIGIDO
2. Verifique se há apenas 1 bloco always atribuindo cada sinal
```

**Erro**: "File not found: xxx.v"
```
Solução:
1. Verifique se todos os 10 arquivos .v estão na pasta
2. Re-adicione os arquivos: Project → Add Files
```

**Erro**: "Top-level entity is undefined"
```
Solução:
1. Project → Set as Top-Level Entity
2. Selecione: projeto_vinho_top
```

---

### Problema 2: Não encontra a placa

**Erro**: "No hardware detected"
```
Solução:
1. Verifique conexão USB
2. Reinstale drivers USB-Blaster:
   - Windows: quartus/drivers/usb-blaster
   - Linux: sudo apt-get install quartus-prime-programmer
3. Tente outra porta USB
```

---

### Problema 3: LEDs não acendem

**Sintoma**: Placa programada mas nada acontece
```
Diagnóstico:
1. Pressione KEY[1] (Reset)
2. Verifique displays HEX0-HEX3
   - Se mostrarem "20" e "00": Pin assignment OK
   - Se estiverem apagados: Pin assignment ERRADO

Solução:
1. Verifique Pin Assignment no Quartus
2. Recompile e reprograme
```

---

### Problema 4: Motor não para

**Sintoma**: LEDR[9] não apaga ao ligar SW[0]
```
Causa provável: FSM Mealy não está respondendo

Diagnóstico:
1. Verifique se SW[0] está funcionando (teste com multímetro)
2. Verifique conexão do pino no Pin Planner

Solução temporária:
- Pressione KEY[1] (Reset) para parar o motor
```

---

### Problema 5: Displays mostram valores estranhos

**Sintoma**: HEX mostra letras ou símbolos errados
```
Causa: Pin assignment incorreto ou decodificador com bug

Solução:
1. Verifique todos os 28 pinos dos displays (HEX0-HEX3)
2. Certifique-se que está usando decodificador_display.v correto
```

---

## 📊 Indicadores Visuais da Placa

### LEDs e Seu Significado

```
LEDR[9] 🟢 = Motor ligado (esteira se movendo)
LEDR[8] 🔵 = Válvula de enchimento ativa
LEDR[7] 🟡 = Vedação em progresso
LEDR[6] 🔴 = Descarte ativo (garrafa reprovada)
LEDR[5] 🟣 = Dispensador repondo rolhas
LEDR[0] 🔴 = ALARME! Falta de rolhas

HEX3-HEX2: "XX" = Contador de dúzias (0-99)
HEX1-HEX0: "XX" = Contador de rolhas (0-99)
```

### Sequência Normal de LEDs

Durante um ciclo completo, você verá:
```
LEDR[9] → LEDR[8] → LEDR[7] → LEDR[9] → LEDR[9] → Final
(Motor)   (Válvula) (Vedação)  (Motor)   (Motor)
```

---

## 🎓 Cenários Avançados

### Cenário 1: Simulação de Produção Contínua

Simule uma linha de produção real com múltiplas garrafas:

```
1. Configure "autômato" usando os switches:
   - Prenda SW[0-4] com fita adesiva na posição ligada
   - SW[3] ligado (sempre aprova)

2. Pressione START repetidamente
   
3. Observe:
   - Rolhas diminuem automaticamente
   - Dúzias aumentam automaticamente
   - Reposição automática em ação
   - Reset automático de dúzias em 10
```

### Cenário 2: Teste de Estresse

Teste os limites do sistema:

```
1. Ligue TODOS os switches ao mesmo tempo
2. Pressione START
3. Observe: Sistema deve lidar graciosamente
4. Cada FSM deve responder apenas ao seu sensor correto
```

### Cenário 3: Recuperação de Falta de Rolha

Simule falta de rolha no meio do processo:

```
1. Inicie processo normal
2. Use SW[7] para reduzir rolhas manualmente até 0
3. Observe: Sistema para imediatamente
4. Use SW[7] para adicionar rolhas
5. Observe: Sistema retoma funcionamento
```

---

## 📝 Checklist de Validação

Use este checklist para validar o funcionamento completo:

### ✅ Hardware
- [ ] Placa conectada e ligada
- [ ] USB-Blaster detectado no Quartus
- [ ] Programação bem-sucedida

### ✅ Displays
- [ ] HEX1-HEX0 mostra "20" após reset
- [ ] HEX3-HEX2 mostra "00" após reset
- [ ] Displays incrementam/decrementam corretamente

### ✅ Botões
- [ ] KEY[1] (Reset) funciona
- [ ] KEY[0] (START) inicia processo

### ✅ Sensores (Switches)
- [ ] SW[0] para o motor
- [ ] SW[1] para o enchimento
- [ ] SW[2] detecta posição CQ
- [ ] SW[3] aprova/reprova
- [ ] SW[4] incrementa dúzias
- [ ] SW[7] adiciona rolhas

### ✅ Atuadores (LEDs)
- [ ] LEDR[9] (Motor) funciona
- [ ] LEDR[8] (Válvula) funciona
- [ ] LEDR[7] (Vedação) pisca 0.5s
- [ ] LEDR[6] (Descarte) pisca 0.5s
- [ ] LEDR[5] (Dispensador) pisca 1s
- [ ] LEDR[0] (Alarme) acende quando rolhas = 0

### ✅ Lógica
- [ ] Ciclo completo funciona
- [ ] Decremento de rolhas funciona
- [ ] Incremento de dúzias funciona
- [ ] Reposição automática funciona
- [ ] Reset automático dúzias funciona
- [ ] Alarme de rolha funciona
- [ ] Descarte funciona

---

## 🎉 Conclusão

Se você completou todos os testes acima, **parabéns!** 🎊

Seu sistema está:
- ✅ Compilado corretamente
- ✅ Programado na FPGA
- ✅ Funcionando perfeitamente
- ✅ Pronto para demonstração

---

## 📞 Suporte

### Documentação Adicional
- `README.md` - Visão geral do projeto
- `DATAPATH_DETALHADO.md` - Análise técnica
- `VALIDACAO_REQUISITOS_FINAL.md` - Validação oficial
- `CORRECAO_BUG_CRITICO.md` - Correção do bug Mestre-Esteira

### Vídeos Sugeridos (YouTube)
- "DE10-Lite Getting Started"
- "Quartus Prime Tutorial"
- "FPGA Programming Basics"

---

**Desenvolvido para:** TEC498 - MI Circuitos Digitais  
**Instituição:** UEFS  
**Data:** Novembro 2025

🚀 **Boa sorte com seu projeto!** 🚀

