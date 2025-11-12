// ============================================================================
// Módulo: fsm_mestre.v
// Descrição: FSM MOORE - Sequenciador Principal (Mestre)
//            Coordena todas as FSMs escravas
//            Envia comandos e aguarda sinais de tarefa_concluida
// Tipo: Verilog COMPORTAMENTAL (FSM MOORE)
// ============================================================================

module fsm_mestre (
    input wire clk,                          // Clock de 50MHz
    input wire reset,                        // Reset global
    input wire start,                        // Pulso do botão START (KEY0)
    input wire alarme_rolha,                 // Alarme de falta de rolha
    input wire sensor_final,                 // SW4 - Sensor final da esteira
    
    // Sinais das FSMs escravas (DISTINTOS)
    input wire esteira_concluida_enchimento, // Esteira 1 (Enchimento) concluída
    input wire esteira_concluida_cq,         // Esteira 2 (CQ) concluída
    input wire esteira_concluida_final,      // Esteira 3 (Final) concluída
    input wire enchimento_concluido,         // Enchimento finalizado
    input wire vedacao_concluida,            // Vedação finalizada
    input wire cq_concluida,                 // Controle de qualidade finalizado
    input wire garrafa_aprovada,             // Garrafa foi aprovada no CQ
    
    // Comandos para FSMs escravas (DISTINTOS)
    output reg cmd_mover_para_enchimento,    // Comando para FSM Esteira 1
    output reg cmd_mover_para_cq,            // Comando para FSM Esteira 2
    output reg cmd_mover_para_final,         // Comando para FSM Esteira 3
    output reg cmd_encher,                   // Comando para encher
    output reg cmd_vedar,                    // Comando para vedar
    output reg cmd_verificar_cq,             // Comando para verificar CQ
    
    // Sinal para contador de dúzias
    output reg incrementar_duzia             // Incrementa contador ao final
);

    // Estados da FSM Mestre
    localparam IDLE = 4'd0;
    localparam MOVER_PARA_ENCHIMENTO = 4'd1;
    localparam AGUARDA_ESTEIRA_1 = 4'd2;
    localparam ENCHENDO = 4'd3;
    localparam AGUARDA_ENCHIMENTO = 4'd4;
    localparam VEDANDO = 4'd5;
    localparam AGUARDA_VEDACAO = 4'd6;
    localparam MOVER_PARA_CQ = 4'd7;
    localparam AGUARDA_ESTEIRA_2 = 4'd8;
    localparam VERIFICANDO_CQ = 4'd9;
    localparam AGUARDA_CQ = 4'd10;
    localparam MOVER_PARA_FINAL = 4'd11;
    localparam AGUARDA_ESTEIRA_3 = 4'd12;
    localparam CONTANDO_FINAL = 4'd13;
    localparam PARADO_SEM_ROLHA = 4'd14;
    
    reg [3:0] estado_atual;
    
    // Sincronização do sensor final
    reg sensor_final_prev;
    wire pulso_sensor_final;
    
    assign pulso_sensor_final = sensor_final && !sensor_final_prev;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sensor_final_prev <= 1'b0;
        end else begin
            sensor_final_prev <= sensor_final;
        end
    end
    
    // ========================================================================
    // LÓGICA DE TRANSIÇÃO DE ESTADOS (SEQUENCIAL)
    // ========================================================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            estado_atual <= IDLE;
        end else begin
            case (estado_atual)
                // ============================================================
                // Estado IDLE - Aguarda comando START
                // ============================================================
                IDLE: begin
                    if (start) begin
                        if (alarme_rolha) begin
                            // Se não há rolhas, não inicia o processo
                            estado_atual <= PARADO_SEM_ROLHA;
                        end else begin
                            // Inicia o processo
                            estado_atual <= MOVER_PARA_ENCHIMENTO;
                        end
                    end
                end
                
                // ============================================================
                // Estado PARADO_SEM_ROLHA - Sistema parado por falta de rolhas
                // ============================================================
                PARADO_SEM_ROLHA: begin
                    if (!alarme_rolha) begin
                        // Rolhas foram repostas, pode continuar
                        estado_atual <= IDLE;
                    end
                end
                
                // ============================================================
                // FASE 1: Movimento até o ponto de enchimento
                // ============================================================
                MOVER_PARA_ENCHIMENTO: begin
                    // Aguarda 1 ciclo para enviar comando
                    estado_atual <= AGUARDA_ESTEIRA_1;
                end
                
                AGUARDA_ESTEIRA_1: begin
                    if (esteira_concluida_enchimento) begin
                        // Esteira parou no sensor de enchimento
                        estado_atual <= ENCHENDO;
                    end
                    // Se ficar sem rolha durante movimento
                    if (alarme_rolha) begin
                        estado_atual <= PARADO_SEM_ROLHA;
                    end
                end
                
                // ============================================================
                // FASE 2: Enchimento da garrafa
                // ============================================================
                ENCHENDO: begin
                    estado_atual <= AGUARDA_ENCHIMENTO;
                end
                
                AGUARDA_ENCHIMENTO: begin
                    if (enchimento_concluido) begin
                        // Enchimento finalizado
                        estado_atual <= VEDANDO;
                    end
                end
                
                // ============================================================
                // FASE 3: Vedação da garrafa
                // ============================================================
                VEDANDO: begin
                    estado_atual <= AGUARDA_VEDACAO;
                end
                
                AGUARDA_VEDACAO: begin
                    if (vedacao_concluida) begin
                        // Vedação finalizada
                        estado_atual <= MOVER_PARA_CQ;
                    end
                    // Se ficar sem rolha durante vedação
                    if (alarme_rolha) begin
                        estado_atual <= PARADO_SEM_ROLHA;
                    end
                end
                
                // ============================================================
                // FASE 4: Movimento até o controle de qualidade
                // ============================================================
                MOVER_PARA_CQ: begin
                    estado_atual <= AGUARDA_ESTEIRA_2;
                end
                
                AGUARDA_ESTEIRA_2: begin
                    if (esteira_concluida_cq) begin
                        // Esteira parou no sensor CQ
                        estado_atual <= VERIFICANDO_CQ;
                    end
                    if (alarme_rolha) begin
                        estado_atual <= PARADO_SEM_ROLHA;
                    end
                end
                
                // ============================================================
                // FASE 5: Controle de qualidade
                // ============================================================
                VERIFICANDO_CQ: begin
                    estado_atual <= AGUARDA_CQ;
                end
                
                AGUARDA_CQ: begin
                    if (cq_concluida) begin
                        // CQ finalizado (aprovado ou descartado)
                        if (garrafa_aprovada) begin
                            // Garrafa aprovada, segue para final
                            estado_atual <= MOVER_PARA_FINAL;
                        end else begin
                            // Garrafa reprovada, volta ao início
                            estado_atual <= IDLE;
                        end
                    end
                end
                
                // ============================================================
                // FASE 6: Movimento até o sensor final
                // ============================================================
                MOVER_PARA_FINAL: begin
                    estado_atual <= AGUARDA_ESTEIRA_3;
                end
                
                AGUARDA_ESTEIRA_3: begin
                    if (esteira_concluida_final) begin
                        // Esteira parou no sensor final
                        estado_atual <= CONTANDO_FINAL;
                    end
                    if (alarme_rolha) begin
                        estado_atual <= PARADO_SEM_ROLHA;
                    end
                end
                
                // ============================================================
                // FASE 7: Contagem final (incrementa dúzias)
                // ============================================================
                CONTANDO_FINAL: begin
                    // Aguarda o sensor final detectar a garrafa
                    if (pulso_sensor_final) begin
                        // Garrafa contada, volta ao início para próxima
                        estado_atual <= IDLE;
                    end
                end
                
                default: begin
                    estado_atual <= IDLE;
                end
            endcase
        end
    end
    
    // ========================================================================
    // LÓGICA MOORE: Saídas dependem APENAS do ESTADO
    // ========================================================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            cmd_mover_para_enchimento <= 1'b0;
            cmd_mover_para_cq <= 1'b0;
            cmd_mover_para_final <= 1'b0;
            cmd_encher <= 1'b0;
            cmd_vedar <= 1'b0;
            cmd_verificar_cq <= 1'b0;
            incrementar_duzia <= 1'b0;
        end else begin
            // Valores padrão
            cmd_mover_para_enchimento <= 1'b0;
            cmd_mover_para_cq <= 1'b0;
            cmd_mover_para_final <= 1'b0;
            cmd_encher <= 1'b0;
            cmd_vedar <= 1'b0;
            cmd_verificar_cq <= 1'b0;
            incrementar_duzia <= 1'b0;
            
            case (estado_atual)
                MOVER_PARA_ENCHIMENTO, AGUARDA_ESTEIRA_1: begin
                    cmd_mover_para_enchimento <= 1'b1;
                end
                
                ENCHENDO, AGUARDA_ENCHIMENTO: begin
                    cmd_encher <= 1'b1;
                end
                
                VEDANDO, AGUARDA_VEDACAO: begin
                    cmd_vedar <= 1'b1;
                end
                
                MOVER_PARA_CQ, AGUARDA_ESTEIRA_2: begin
                    cmd_mover_para_cq <= 1'b1;
                end
                
                VERIFICANDO_CQ, AGUARDA_CQ: begin
                    cmd_verificar_cq <= 1'b1;
                end
                
                MOVER_PARA_FINAL, AGUARDA_ESTEIRA_3: begin
                    cmd_mover_para_final <= 1'b1;
                end
                
                CONTANDO_FINAL: begin
                    // Incrementa dúzia quando sensor final detecta
                    incrementar_duzia <= pulso_sensor_final;
                end
                
                default: begin
                    // Todos os comandos desligados
                end
            endcase
        end
    end

endmodule

