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
    input wire [9:0] SW,                     // Chaves da placa (SW[5] e SW[6] agora usados)
    
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
    // MAPEAMENTO DE ENTRADAS (Sensores) - ESTRUTURAL
    // ========================================================================
    wire sensor_posicao_enchimento;          // SW[0]
    wire sensor_nivel;                       // SW[1]
    wire sensor_posicao_cq;                  // SW[2]
    wire resultado_cq;                       // SW[3] (0=Reprovado, 1=Aprovado)
    wire sensor_final;                       // SW[4]
    wire sensor_vedacao;                     // SW[5] (NOVO)
    wire sensor_descarte;                    // SW[6] (NOVO)
    wire sw_adicionar_rolha;                 // SW[7]
    
    buf (sensor_posicao_enchimento, SW[0]);
    buf (sensor_nivel, SW[1]);
    buf (sensor_posicao_cq, SW[2]);
    buf (resultado_cq, SW[3]);
    buf (sensor_final, SW[4]);
    buf (sensor_vedacao, SW[5]);
    buf (sensor_descarte, SW[6]);
    buf (sw_adicionar_rolha, SW[7]);
    
    // ========================================================================
    // MAPEAMENTO DE SAÍDAS (Atuadores) - ESTRUTURAL
    // ========================================================================
    wire alarme_rolha_vazia;                 // LEDR[0]
    wire dispensador_ativo;                  // LEDR[5]
    wire descarte_ativo;                     // LEDR[6]
    wire vedacao_ativa;                      // LEDR[7]
    wire valvula_ativa;                      // LEDR[8]
    wire motor_ativo;                        // LEDR[9]
    
    // Constantes para LEDs não usados
    supply0 gnd;
    wire zero_const;
    buf (zero_const, gnd);
    
    buf (LEDR[0], alarme_rolha_vazia);
    buf (LEDR[1], zero_const);
    buf (LEDR[2], zero_const);
    buf (LEDR[3], zero_const);
    buf (LEDR[4], zero_const);
    buf (LEDR[5], dispensador_ativo);
    buf (LEDR[6], descarte_ativo);
    buf (LEDR[7], vedacao_ativa);
    buf (LEDR[8], valvula_ativa);
    buf (LEDR[9], motor_ativo);
    
    // ========================================================================
    // SINAIS INTERNOS (WIRES)
    // ========================================================================
    
    wire clk;
    wire reset;
    wire not_key1;
    
    buf (clk, CLOCK_50);
    not (not_key1, KEY[1]);                  // KEY[1] é ativo baixo
    buf (reset, not_key1);
    
    wire pulso_start;
    
    // Sinais da FSM Mestre
    wire cmd_encher;
    wire cmd_vedar;
    wire cmd_verificar_cq;
    wire incrementar_duzia;
    
    // Sinais das FSMs Escravas
    wire enchimento_concluido;
    wire vedacao_concluida;
    wire cq_concluida;
    wire garrafa_aprovada;
    
    // Sinais dos contadores
    wire decrementar_rolha;
    wire [6:0] contador_rolhas;
    wire [6:0] contador_duzias;
    
    // ========================================================================
    // INSTANCIAÇÃO DOS MÓDULOS
    // ========================================================================
    
    // 1. DEBOUNCER para START (KEY0)
    debounce debounce_start (
        .clk(clk),
        .reset(reset),
        .button_in(KEY[0]),
        .pulse_out(pulso_start)
    );
    
    // 2. FSM MESTRE (Sequenciador Principal)
    fsm_mestre fsm_mestre_inst (
        .clk(clk),
        .reset(reset),
        .start(pulso_start),
        .alarme_rolha(alarme_rolha_vazia),
        
        // Sensores
        .sensor_enchimento(sensor_posicao_enchimento),
        .sensor_vedacao(sensor_vedacao),
        .sensor_cq(sensor_posicao_cq),
        .sensor_descarte(sensor_descarte),
        .sensor_final(sensor_final),
        
        // Inputs das FSMs escravas
        .enchimento_concluido(enchimento_concluido),
        .vedacao_concluida(vedacao_concluida),
        .cq_concluida(cq_concluida),
        .garrafa_aprovada(garrafa_aprovada),
        
        // Outputs Comandos
        .motor_ativo(motor_ativo),      // Controle DIRETO do motor
        .cmd_encher(cmd_encher),
        .cmd_vedar(cmd_vedar),
        .cmd_verificar_cq(cmd_verificar_cq),
        .descarte_ativo(descarte_ativo), // Controle DIRETO do descarte
        .incrementar_duzia(incrementar_duzia)
    );
    
    // 3. FSM ESTEIRA - REMOVIDA (Simplificação Arquitetural)
    
    // 4. FSM ENCHIMENTO
    fsm_enchimento fsm_enchimento_inst (
        .clk(clk),
        .reset(reset),
        .cmd_iniciar(cmd_encher),
        .sensor_nivel(sensor_nivel),
        .valvula_ativa(valvula_ativa),
        .tarefa_concluida(enchimento_concluido)
    );
    
    // 5. FSM VEDAÇÃO
    fsm_vedacao fsm_vedacao_inst (
        .clk(clk),
        .reset(reset),
        .cmd_iniciar(cmd_vedar),
        .alarme_rolha(alarme_rolha_vazia),
        .vedacao_ativa(vedacao_ativa),
        .decrementar_rolha(decrementar_rolha),
        .tarefa_concluida(vedacao_concluida)
    );
    
    // 6. FSM CONTROLE DE QUALIDADE
    fsm_cq_descarte fsm_cq_inst (
        .clk(clk),
        .reset(reset),
        .cmd_verificar(cmd_verificar_cq),
        .sensor_cq(sensor_posicao_cq),
        .pulso_start(pulso_start),
        .resultado_cq(resultado_cq),
        //.descarte_ativo(descarte_ativo), // Agora controlado pelo Mestre
        .garrafa_aprovada(garrafa_aprovada),
        .tarefa_concluida(cq_concluida)
    );
    
    // 7. CONTADOR DE ROLHAS
    contador_rolhas contador_rolhas_inst (
        .clk(clk),
        .reset(reset),
        .decrementar(decrementar_rolha),
        .sw_adicionar_manual(sw_adicionar_rolha),
        .dispensador_ativo(dispensador_ativo),
        .alarme_rolha_vazia(alarme_rolha_vazia),
        .contador_valor(contador_rolhas)
    );
    
    // 8. CONTADOR DE DÚZIAS
    contador_duzias contador_duzias_inst (
        .clk(clk),
        .reset(reset),
        .zera_contagem(pulso_start),     // FIX: Start zera contagem
        .incrementar(incrementar_duzia),
        .contador_valor(contador_duzias)
    );
    
    // 9. DECODIFICADOR DISPLAY - ROLHAS
    decodificador_display dec_rolhas (
        .valor(contador_rolhas),
        .hex1(HEX1),
        .hex0(HEX0)
    );
    
    // 10. DECODIFICADOR DISPLAY - DÚZIAS
    decodificador_display dec_duzias (
        .valor(contador_duzias),
        .hex1(HEX3),
        .hex0(HEX2)
    );

endmodule
