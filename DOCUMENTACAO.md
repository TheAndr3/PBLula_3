# Documentação do Projeto: Controlador de Linha de Produção de Vinho (VINHOVASF)

## 1. Introdução e Contexto

Este documento formaliza o desenvolvimento de um sistema digital para automação de uma linha de produção de vinhos, atendendo aos requisitos do **Problema 3** da disciplina **TEC498 - Circuitos Digitais (2025.2)**.

O objetivo é simular, utilizando a placa FPGA **DE10-Lite**, o controle sequencial de envase, vedação, inspeção e contagem de garrafas.

---

## 2. Descrição do Problema

O sistema deve controlar uma esteira que transporta garrafas por três estações principais:
1.  **Enchimento**: A garrafa é detectada, a esteira para, e a válvula é acionada até que o sensor de nível indique que está cheia.
2.  **Vedação**: Se houver rolhas disponíveis, um atuador insere a rolha. O sistema deve gerenciar o estoque de rolhas, permitindo recarga manual ou automática.
3.  **Controle de Qualidade (CQ)**: A garrafa é inspecionada. Se aprovada, segue para contagem; se reprovada, é descartada.

Além disso, o sistema deve contabilizar a produção em dúzias e exibir o estoque de rolhas.

---

## 3. Arquitetura da Solução Atual

Atualmente, o projeto encontra-se em estágio de implementação funcional utilizando uma abordagem de **Máquina de Estados Finita (FSM) Centralizada**, implementada no módulo `fsm_main.v`. Embora existam arquivos para uma abordagem modular (Mestre-Escravo), a versão ativa no `projeto_vinho_top.v` utiliza a FSM única para coordenar todo o fluxo.

### 3.1. Diagrama de Blocos (Nível de Topo)

O módulo `projeto_vinho_top.v` (Estrutural) conecta os seguintes componentes:

*   **Controlador Central (`fsm_main`)**: Gerencia os estados do sistema (Motor, Válvulas, Atuadores).
*   **Contadores**:
    *   `contador_rolhas.v`: Gerencia o decremento e reposição de rolhas (Display HEX1-HEX0).
    *   `contador_duzias_v2.v`: Conta garrafas aprovadas (Display HEX3-HEX2).
*   **Interface de Entrada**:
    *   `debounce.v`: Filtro para botões mecânicos (START e Adicionar Rolha).
*   **Interface de Saída**:
    *   `decodificador_display.v`: Converte valores binários para 7-segmentos.

### 3.2. Máquina de Estados (FSM Main)

A lógica de controle (`fsm_main.v`) opera com os seguintes estados:

1.  **IDLE (0000)**: Estado inicial. Aguarda sinal de `START` (KEY0). Reinicia variáveis.
2.  **ESTEIRA (0001)**: Liga o motor (`LEDR[9]`).
    *   *Nota Atual*: Avança por tempo (timer de 1s) simulando o deslocamento até a próxima estação.
3.  **ENCHENDO (0010)**: Para o motor e liga a válvula (`LEDR[8]`).
    *   Aguarda o sensor de nível (`SW[1]`) ficar alto.
    *   Se acabar rolha (`alarme_rolha`), volta para IDLE.
4.  **VEDANDO (0011)**: Liga o atuador de vedação (`LEDR[7]`) e decrementa o contador de rolhas.
    *   Permanece por 1 segundo (Timer).
5.  **POSICAO_CQ (0101)**: Aguarda decisão do operador sobre a qualidade.
    *   Se `SW[2]` (Aprovado): Vai para estado APROVADO.
    *   Se `SW[3]` (Reprovado): Vai para estado DESCARTANDO.
6.  **DESCARTANDO (0110)**: Ativa o descarte (`LEDR[6]`) por 1 segundo, depois retorna à ESTEIRA.
7.  **APROVADO (0111)**: Incrementa contagem de dúzias, aguarda 1 segundo e retorna à ESTEIRA.

### 3.3. Mapeamento de Hardware

| Periférico | Função no Projeto | Observação |
| :--- | :--- | :--- |
| **KEY0** | Iniciar Sistema (Start) | Ativo Baixo |
| **KEY1** | Reset Global | Ativo Baixo |
| **SW[1]** | Sensor de Nível (Enchimento) | High = Cheio |
| **SW[2]** | Botão de Aprovação (CQ) | High = Aprovar |
| **SW[3]** | Botão de Reprovação (CQ) | High = Reprovar |
| **SW[7]** | Adicionar Rolha Manual | Pulso único |
| **LEDR[9]** | Motor da Esteira | |
| **LEDR[8]** | Válvula de Enchimento | |
| **LEDR[7]** | Atuador de Vedação | |
| **LEDR[6]** | Atuador de Descarte | |
| **LEDR[0]** | Alarme (Sem Rolhas) | |
| **HEX1-0** | Contador de Rolhas | 00 a 99 |
| **HEX3-2** | Contador de Dúzias | 00 a 10 |

---

## 4. Estado Atual do Desenvolvimento

O projeto possui duas vertentes de código presentes no diretório:

1.  **Versão Ativa (Monolítica)**: 
    *   Utiliza `fsm_main.v` instanciado no topo.
    *   **Status**: Funcional para testes de fluxo. Utiliza timers para simular o movimento da esteira entre estações, simplificando a necessidade de acionar múltiplos switches de posição (`SW[0]`, `SW[4]`) durante os testes manuais.
    *   **Limitação**: A lógica de sensores de posição da esteira foi substituída temporariamente por temporizadores na FSM principal.

2.  **Versão Modular (Legado/Futuro)**:
    *   Arquivos `fsm_mestre.v`, `fsm_esteira.v`, `fsm_enchimento.v`, etc.
    *   **Status**: Presentes no diretório mas comentados/não instanciados no arquivo topo `projeto_vinho_top.v`.
    *   Esta versão visava uma arquitetura distribuída onde cada estação tinha sua própria FSM.

## 5. Instruções de Operação (Versão Atual)

Para validar o funcionamento na placa:

1.  **Reset**: Pressione `KEY1` para garantir estado inicial.
2.  **Início**: Pressione `KEY0`. O Motor (`LEDR[9]`) ligará por 1 segundo.
3.  **Enchimento**: O sistema para automaticamente no estado de enchimento (`LEDR[8]` aceso).
    *   Ative `SW[1]` para simular "garrafa cheia". O sistema avançará.
4.  **Vedação**: Ocorre automaticamente (`LEDR[7]` acende por 1s). Contador de rolhas decrementa.
5.  **Qualidade**: O sistema para aguardando CQ.
    *   Ative `SW[2]` para **Aprovar** (incrementa dúzias, reinicia ciclo).
    *   OU ative `SW[3]` para **Reprovar** (aciona descarte `LEDR[6]`, reinicia ciclo sem incrementar).
6.  **Rolhas**: Se o contador chegar a 0, o alarme `LEDR[0]` acende e o sistema para. Use `SW[7]` para repor.

---

**Autor:** Equipe de Desenvolvimento VINHOVASF  
**Data:** 28/11/2025
