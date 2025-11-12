// ============================================================================
// Módulo: projeto_vinho_top.v
// Descrição: Módulo Top-Level ESTRUTURAL
//            Integra todos os módulos do sistema
//            NÃO contém lógica always - apenas instanciações e conexões
// Tipo: Verilog ESTRUTURAL
// ============================================================================

module projeto_vinho_top (
    // ========================================================================
    // ENTRADAS DA PLACA DE10-LITE
    // ========================================================================
    input wire CLOCK_50,                     // Clock de 50MHz
    input wire [1:0] KEY,                    // KEY[0]=START, KEY[1]=RESET
    input wire [7:0] SW,                     // Chaves da placa
    
    // ========================================================================
    // SAÍDAS DA PLACA DE10-LITE
    // ========================================================================
    output wire [9:0] LEDR,                  // LEDs vermelhos
    output wire [6:0] HEX0,                  // Display 7-seg (unidade rolhas)
    output wire [6:0] HEX1,                  // Display 7-seg (dezena rolhas)
    output wire [6:0] HEX2,                  // Display 7-seg (unidade dúzias)
    output wire [6:0] HEX3                   // Display 7-seg (dezena dúzias)
);

    // ========================================================================
    // MAPEAMENTO DE ENTRADAS (Sensores)
    // ========================================================================
    wire sensor_posicao_enchimento;          // SW[0]
    wire sensor_nivel;                       // SW[1]
    wire sensor_posicao_cq;                  // SW[2]
    wire resultado_cq;                       // SW[3] (0=Reprovado, 1=Aprovado)
    wire sensor_final;                       // SW[4]
    wire sw_adicionar_rolha;                 // SW[7]
    
    assign sensor_posicao_enchimento = SW[0];
    assign sensor_nivel = SW[1];
    assign sensor_posicao_cq = SW[2];
    assign resultado_cq = SW[3];
    assign sensor_final = SW[4];
    assign sw_adicionar_rolha = SW[7];
    
    // ========================================================================
    // MAPEAMENTO DE SAÍDAS (Atuadores)
    // ========================================================================
    wire alarme_rolha_vazia;                 // LEDR[0]
    wire dispensador_ativo;                  // LEDR[5]
    wire descarte_ativo;                     // LEDR[6]
    wire vedacao_ativa;                      // LEDR[7]
    wire valvula_ativa;                      // LEDR[8]
    wire motor_ativo;                        // LEDR[9]
    
    assign LEDR[0] = alarme_rolha_vazia;
    assign LEDR[1] = 1'b0;                   // Não usado
    assign LEDR[2] = 1'b0;                   // Não usado
    assign LEDR[3] = 1'b0;                   // Não usado
    assign LEDR[4] = 1'b0;                   // Não usado
    assign LEDR[5] = dispensador_ativo;
    assign LEDR[6] = descarte_ativo;
    assign LEDR[7] = vedacao_ativa;
    assign LEDR[8] = valvula_ativa;
    assign LEDR[9] = motor_ativo;
    
    // ========================================================================
    // SINAIS INTERNOS (WIRES)
    // ========================================================================
    
    // Sinais de reset e clock
    wire clk;
    wire reset;
    
    assign clk = CLOCK_50;
    assign reset = ~KEY[1];                  // KEY[1] é ativo baixo
    
    // Sinais dos debouncers
    wire pulso_start;
    wire pulso_reset;
    
    // Sinais da FSM Mestre
    wire cmd_mover_esteira;
    wire cmd_encher;
    wire cmd_vedar;
    wire cmd_verificar_cq;
    wire incrementar_duzia;
    
    // Sinais das FSMs Escravas
    wire esteira_concluida;
    wire enchimento_concluido;
    wire vedacao_concluida;
    wire cq_concluida;
    wire garrafa_aprovada;
    
    // Sinais dos contadores
    wire decrementar_rolha;
    wire [6:0] contador_rolhas;
    wire [6:0] contador_duzias;
    
    // Sinais combinados para a FSM Esteira
    // A FSM esteira precisa saber qual sensor usar dependendo do contexto
    // Vamos criar uma lógica simples: usará diferentes sensores em momentos diferentes
    // Para simplificar, vamos usar um MUX controlado pelo estado da FSM Mestre
    
    // NOTA: A FSM Esteira será usada para todos os movimentos
    // O sensor apropriado deve ser selecionado baseado no comando atual
    // Vamos criar 3 instâncias separadas para maior clareza
    
    // Movimento 1: Até enchimento (sensor SW0)
    wire motor_ativo_1;
    wire esteira_concluida_1;
    
    // Movimento 2: Até CQ (sensor SW2)
    wire motor_ativo_2;
    wire esteira_concluida_2;
    
    // Movimento 3: Até final (sensor SW4)
    wire motor_ativo_3;
    wire esteira_concluida_3;
    
    // Combinar os motores (OR lógico - qualquer um ativo liga o motor)
    assign motor_ativo = motor_ativo_1 | motor_ativo_2 | motor_ativo_3;
    
    // Combinar os sinais de conclusão (OR lógico)
    assign esteira_concluida = esteira_concluida_1 | esteira_concluida_2 | esteira_concluida_3;
    
    // ========================================================================
    // INSTANCIAÇÃO DOS MÓDULOS
    // ========================================================================
    
    // ------------------------------------------------------------------------
    // 1. DEBOUNCER para START (KEY0)
    // ------------------------------------------------------------------------
    debounce debounce_start (
        .clk(clk),
        .reset(reset),
        .button_in(KEY[0]),
        .pulse_out(pulso_start)
    );
    
    // ------------------------------------------------------------------------
    // 2. FSM MESTRE (Sequenciador Principal)
    // ------------------------------------------------------------------------
    fsm_mestre fsm_mestre_inst (
        .clk(clk),
        .reset(reset),
        .start(pulso_start),
        .alarme_rolha(alarme_rolha_vazia),
        .sensor_final(sensor_final),
        
        // Sinais das FSMs escravas
        .esteira_concluida(esteira_concluida),
        .enchimento_concluido(enchimento_concluido),
        .vedacao_concluida(vedacao_concluida),
        .cq_concluida(cq_concluida),
        .garrafa_aprovada(garrafa_aprovada),
        
        // Comandos para FSMs escravas
        .cmd_mover_esteira(cmd_mover_esteira),
        .cmd_encher(cmd_encher),
        .cmd_vedar(cmd_vedar),
        .cmd_verificar_cq(cmd_verificar_cq),
        
        // Sinal para contador de dúzias
        .incrementar_duzia(incrementar_duzia)
    );
    
    // ------------------------------------------------------------------------
    // 3. FSM ESTEIRA - Movimento 1 (até enchimento)
    // ------------------------------------------------------------------------
    fsm_esteira fsm_esteira_1 (
        .clk(clk),
        .reset(reset),
        .cmd_mover(cmd_mover_esteira),
        .sensor_destino(sensor_posicao_enchimento),
        .alarme_rolha(alarme_rolha_vazia),
        .motor_ativo(motor_ativo_1),
        .tarefa_concluida(esteira_concluida_1)
    );
    
    // ------------------------------------------------------------------------
    // 4. FSM ESTEIRA - Movimento 2 (até CQ)
    // ------------------------------------------------------------------------
    fsm_esteira fsm_esteira_2 (
        .clk(clk),
        .reset(reset),
        .cmd_mover(cmd_mover_esteira),
        .sensor_destino(sensor_posicao_cq),
        .alarme_rolha(alarme_rolha_vazia),
        .motor_ativo(motor_ativo_2),
        .tarefa_concluida(esteira_concluida_2)
    );
    
    // ------------------------------------------------------------------------
    // 5. FSM ESTEIRA - Movimento 3 (até final)
    // ------------------------------------------------------------------------
    fsm_esteira fsm_esteira_3 (
        .clk(clk),
        .reset(reset),
        .cmd_mover(cmd_mover_esteira),
        .sensor_destino(sensor_final),
        .alarme_rolha(alarme_rolha_vazia),
        .motor_ativo(motor_ativo_3),
        .tarefa_concluida(esteira_concluida_3)
    );
    
    // ------------------------------------------------------------------------
    // 6. FSM ENCHIMENTO
    // ------------------------------------------------------------------------
    fsm_enchimento fsm_enchimento_inst (
        .clk(clk),
        .reset(reset),
        .cmd_iniciar(cmd_encher),
        .sensor_nivel(sensor_nivel),
        .valvula_ativa(valvula_ativa),
        .tarefa_concluida(enchimento_concluido)
    );
    
    // ------------------------------------------------------------------------
    // 7. FSM VEDAÇÃO
    // ------------------------------------------------------------------------
    fsm_vedacao fsm_vedacao_inst (
        .clk(clk),
        .reset(reset),
        .cmd_iniciar(cmd_vedar),
        .alarme_rolha(alarme_rolha_vazia),
        .vedacao_ativa(vedacao_ativa),
        .decrementar_rolha(decrementar_rolha),
        .tarefa_concluida(vedacao_concluida)
    );
    
    // ------------------------------------------------------------------------
    // 8. FSM CONTROLE DE QUALIDADE E DESCARTE
    // ------------------------------------------------------------------------
    fsm_cq_descarte fsm_cq_inst (
        .clk(clk),
        .reset(reset),
        .cmd_verificar(cmd_verificar_cq),
        .sensor_cq(sensor_posicao_cq),
        .resultado_cq(resultado_cq),
        .descarte_ativo(descarte_ativo),
        .garrafa_aprovada(garrafa_aprovada),
        .tarefa_concluida(cq_concluida)
    );
    
    // ------------------------------------------------------------------------
    // 9. CONTADOR DE ROLHAS
    // ------------------------------------------------------------------------
    contador_rolhas contador_rolhas_inst (
        .clk(clk),
        .reset(reset),
        .decrementar(decrementar_rolha),
        .sw_adicionar_manual(sw_adicionar_rolha),
        .dispensador_ativo(dispensador_ativo),
        .alarme_rolha_vazia(alarme_rolha_vazia),
        .contador_valor(contador_rolhas)
    );
    
    // ------------------------------------------------------------------------
    // 10. CONTADOR DE DÚZIAS
    // ------------------------------------------------------------------------
    contador_duzias contador_duzias_inst (
        .clk(clk),
        .reset(reset),
        .incrementar(incrementar_duzia),
        .reset_manual(pulso_start),
        .contador_valor(contador_duzias)
    );
    
    // ------------------------------------------------------------------------
    // 11. DECODIFICADOR DISPLAY - ROLHAS (HEX1-HEX0)
    // ------------------------------------------------------------------------
    decodificador_display dec_rolhas (
        .valor(contador_rolhas),
        .hex1(HEX1),
        .hex0(HEX0)
    );
    
    // ------------------------------------------------------------------------
    // 12. DECODIFICADOR DISPLAY - DÚZIAS (HEX3-HEX2)
    // ------------------------------------------------------------------------
    decodificador_display dec_duzias (
        .valor(contador_duzias),
        .hex1(HEX3),
        .hex0(HEX2)
    );

endmodule

