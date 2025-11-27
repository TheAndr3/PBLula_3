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
    // MAPEAMENTO DE ENTRADAS (Sensores) - ESTRUTURAL
    // ========================================================================
    wire sensor_posicao_enchimento;          // SW[0]
    wire sensor_nivel;                       // SW[1]
    wire aprovado_cq;                        // SW[2]  Aprovado
    wire reprovado_cq;                       // SW[3] (Reprovado)
    wire sensor_posicao_cq;                   // SW[4]		
    wire sw_adicionar_rolha;                 // SW[7]
	 wire iniciar;
    
    buf (sensor_posicao_enchimento, SW[0]);
    buf (sensor_nivel, SW[1]);
    buf (aprovado_cq, SW[2]);
    buf (reprovado_cq, SW[3]);
	 debounce debounce_add_rolha (
        .clk(clk),
        .reset(reset),
        .button_in(SW[7]),
        .pulse_out(sw_adicionar_rolha)
    );
	 
	 not (iniciar, KEY[0]);
    
    // ========================================================================
    // MAPEAMENTO DE SAÍDAS (Atuadores) - ESTRUTURAL
    // ========================================================================
    wire alarme_rolha_vazia;                 // LEDR[0]
    wire dispensador_ativo;                  // LEDR[5]
    wire descarte_ativo;                     // LEDR[6]
    wire vedacao_ativa;                      // LEDR[7]
    wire valvula_ativa;                      // LEDR[8]
    wire motor_ativo;                        // LEDR[9]
    
    // Constantes para LEDs não usados (usando supply0 diretamente)
    supply0 gnd;  // Fonte de terra (0 lógico)
    wire zero_const;
    buf (zero_const, gnd);
    
    buf (LEDR[0], alarme_rolha_vazia);
    //buf (LEDR[1], zero_const);               // Não usado
    //buf (LEDR[2], zero_const);               // Não usado
    buf (LEDR[3], zero_const);               // Não usado
    and (LEDR[4], posicao_cq);               // Não usado
    buf (LEDR[5], dispensador_ativo);
    buf (LEDR[6], descarte_ativo);		// Simula o descarte da garrafa
    buf (LEDR[7], vedacao_ativa);
    buf (LEDR[8], valvula_ativa);
    buf (LEDR[9], motor_ativo);
    
    // ========================================================================
    // SINAIS INTERNOS (WIRES)
    // ========================================================================
    
    // Sinais de reset e clock
    wire clk;
    wire reset;
    wire not_key1;
    
    buf (clk, CLOCK_50);
    not (not_key1, KEY[1]);                  // KEY[1] é ativo baixo
    buf (reset, not_key1);
    
    // Sinais dos debouncers
    wire pulso_start;
    wire pulso_reset;
    
    // Sinais da FSM Mestre (COMANDOS DISTINTOS)
    wire cmd_mover_para_enchimento;
    wire cmd_mover_para_cq;
    wire cmd_mover_para_final;
    wire cmd_encher;
    wire cmd_vedar;
    wire incrementar_garrafa;
    
    // Sinais das FSMs Escravas
    wire enchimento_concluido;
    wire vedacao_concluida;
    wire cq_concluida;
    wire garrafa_aprovada;
    
    // Sinais dos contadores
    wire decrementar_rolha;
    wire [6:0] contador_rolhas;
    wire [6:0] contador_duzias;
    
    // NOTA: A FSM Esteira será usada para todos os movimentos
    // O sensor apropriado deve ser selecionado baseado no comando atual
    // Vamos criar 3 instâncias separadas para maior clareza
    
    or (motor_ativo, esteira_enchimento);
    
	 // Uma garrafa concluida
	 // Possivelmente sera necessario mudar essa porta end para timer_1s
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
    // 6. FSM ENCHIMENTO
    // ------------------------------------------------------------------------
//	 wire esteira_enchimento;
   // fsm_enchimento fsm_enchimento_inst (
      //  .clk(clk),
     //   .reset(reset),
     //   .cmd_iniciar(iniciar),
     //   .sensor_nivel(sensor_nivel),
	//	  .garrafa_concluida(garrafa_concluida),
	//	  .led1(LEDR[1]),
	//	  .led2(LEDR[2]),
	//	  .esteira(esteira_enchimento),
    //    .valvula_ativa(valvula_ativa),
     //   .tarefa_concluida(enchimento_concluido)
    //);
    
    // ------------------------------------------------------------------------
    // 7. FSM VEDAÇÃO
    // ------------------------------------------------------------------------
    //fsm_vedacao fsm_vedacao_inst (
     //   .clk(clk),
      //  .reset(reset),
      //  .cmd_iniciar(enchimento_concluido),
		 // .cq_concluido(cq_concluida),
      //  .alarme_rolha(alarme_rolha_vazia),
      //  .vedacao_ativa(vedacao_ativa),
       // .decrementar_rolha(decrementar_rolha),
      //  .tarefa_concluida(vedacao_concluida)
    //);
    
	 
	 
    // ------------------------------------------------------------------------
    // 8. FSM CONTROLE DE QUALIDADE E DESCARTE
    // ------------------------------------------------------------------------
	// wire cmd_cq, idle_cq;
	 //and (cmd_cq, vedacao_concluida, enchimento_concluido);
    //fsm_cq_descarte fsm_cq_inst (
     //   .clk(clk),
     //   .reset(reset),
    //    .start(vedacao_concluida),
     //   .aprovado(aprovado_cq),
      //  .reprovado(reprovado_cq),
		 // .garrafa_concluida(garrafa_concluida),
       // .descarte_ativo(descarte_ativo),
       // .garrafa_aprovada(garrafa_aprovada),
       // .tarefa_concluida(cq_concluida),
		  //.estado_idle(idle_cq)
//    );
	 wire posicao_cq;
	 
    fsm_main (
		.clk(clk),                      // Clock de 50MHz
		.reset(reset),                    // Reset global
		.cmd_iniciar(iniciar),              // Comando do mestre para iniciar enchimento
		.sensor_nivel(sensor_nivel),             // SW1 - Sensor de nível (1 = cheia)
		.alarme_rolha(alarme_rolha_vazia),             // Alarme de falta de rolha
		.aprovado(aprovado_cq),                // SW2 - Aprovar CQ
		.reprovado(reprovado_cq),              // SW3 - Reprovar CQ
		.esteira(esteira_enchimento),						// LEDR[9] - Motor ligado
		.valvula_ativa(valvula_ativa),           // LEDR[8] - Válvula de enchimento
		.vedacao_ativa(vedacao_ativa),           // LEDR[7] - Atuador de vedação
		.decrementar_rolha(decrementar_rolha),       // Sinal para decrementar contador
		.descarte_ativo(descarte_ativo),          // LEDR[6] - Atuador de descarte
		.garrafa_aprovada(garrafa_aprovada),        // Sinal para incrementar contador de dúzias
		.posicao_cq(posicao_cq)
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
	 buf (incrementar_garrafa, garrafa_aprovada);
    contador_duzias_v2 contador_duzias_inst (
        .clk(clk),
        .reset(reset),
        .incrementar(incrementar_garrafa),
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

