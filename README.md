# 🍷 Controlador de Linha de Produção de Vinhos - FPGA DE10-Lite

**Status do Projeto**: Em Desenvolvimento (Fase de Testes de Integração)

Este repositório contém o projeto de um controlador digital para uma linha de produção de vinhos, desenvolvido para a disciplina **TEC498 - Circuitos Digitais** (UEFS).

📄 **[Leia a Documentação Completa do Projeto (PT-BR)](./DOCUMENTACAO.md)**

---

## 🚀 Visão Geral da Implementação Atual

O sistema está operando com uma **FSM Centralizada (`fsm_main.v`)** que coordena todas as etapas do processo. Esta abordagem simplifica a validação do fluxo lógico antes da separação em módulos independentes.

### Funcionalidades Ativas
*   ✅ **Ciclo Completo**: Início -> Enchimento -> Vedação -> Inspeção -> Fim.
*   ✅ **Simulação Temporal**: O movimento da esteira é simulado por timers (1 segundo) para facilitar testes manuais sem acionamento constante de sensores de posição.
*   ✅ **Controle de Estoque**: Contador de rolhas funcional com alarme de vazio e reposição (manual/automática).
*   ✅ **Produção**: Contagem de garrafas aprovadas em dúzias.
*   ✅ **Tratamento de Erros**: Descarte de garrafas reprovadas no CQ.

---

## 📂 Estrutura de Arquivos

| Arquivo | Descrição | Status |
| :--- | :--- | :--- |
| `projeto_vinho_top.v` | **Top Level**. Conecta a FSM, contadores e I/O. | **Ativo** |
| `fsm_main.v` | **Lógica de Controle**. FSM central que gerencia o fluxo. | **Ativo** |
| `contador_rolhas.v` | Gerencia quantidade de rolhas e recarga. | **Ativo** |
| `contador_duzias_v2.v` | Conta garrafas finalizadas. | **Ativo** |
| `decodificador_display.v` | Exibe valores nos displays HEX. | **Ativo** |
| `debounce.v` | Filtro para botões `KEY0` e `SW7`. | **Ativo** |
| `fsm_*.v` (outros) | Implementações modulares (Mestre/Escravo). | *Legado/Inativo* |

---

## 🎮 Guia Rápido de Teste

1.  **Carregue** o projeto na DE10-Lite.
2.  **Reset**: Pressione `KEY1`.
3.  **Start**: Pressione `KEY0`.
    *   *Motor (`LEDR9`) liga por 1s.*
4.  **Enchimento**: Quando `LEDR8` (Válvula) acender:
    *   Suba a chave `SW1` (Sensor de Nível) para indicar "Cheio".
    *   *Válvula apaga, Vedação (`LEDR7`) liga.*
5.  **Inspeção (CQ)**: O sistema para aguardando decisão.
    *   Suba `SW2` para **Aprovar** (Incrementa Dúzias).
    *   OU Suba `SW3` para **Reprovar** (Aciona Descarte `LEDR6`).
6.  **Repetição**: O ciclo recomeça automaticamente.

---

## ⚠️ Notas Importantes

*   **Sensores de Posição**: Na versão atual (`fsm_main`), os sensores de posição da esteira (`SW0`, `SW4`) são ignorados em favor de temporizadores para fluidez do teste manual. Apenas o **Sensor de Nível (`SW1`)** e os botões de **CQ (`SW2`/`SW3`)** são exigidos.
*   **Módulos Inativos**: Os arquivos `fsm_mestre.v`, `fsm_esteira.v`, etc., representam uma arquitetura alternativa que não está ligada no `projeto_vinho_top.v` neste momento.

---
*Universidade Estadual de Feira de Santana - 2025.2*