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
    output wire cmd_mover_para_enchimento,    // Comando para FSM Esteira 1
    output wire cmd_mover_para_cq,            // Comando para FSM Esteira 2
    output wire cmd_mover_para_final,         // Comando para FSM Esteira 3
    output wire cmd_encher,                   // Comando para encher
    output wire cmd_vedar,                    // Comando para vedar
    output wire cmd_verificar_cq,             // Comando para verificar CQ
    
    // Sinal para contador de dúzias
    output wire incrementar_duzia             // Incrementa contador ao final
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
    wire not_sensor_final_prev;
    
    // Detecta borda de subida usando portas lógicas
    not (not_sensor_final_prev, sensor_final_prev);
    and (pulso_sensor_final, sensor_final, not_sensor_final_prev);
    
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
                            estado_atual <= MOVER_PARA_ENCHIMENTO;
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
                        estado_atual <= MOVER_PARA_ENCHIMENTO;
                    end
                end
                
                default: begin
                    estado_atual <= IDLE;
                end
            endcase
        end
    end
    
    // ========================================================================
    // LÓGICA MOORE: Saídas dependem APENAS do ESTADO (ESTRUTURAL - PORTAS)
    // ========================================================================
    // Extração dos bits do estado (4 bits: estado_atual[3:0])
    wire state_bit0, state_bit1, state_bit2, state_bit3;
    buf (state_bit0, estado_atual[0]);
    buf (state_bit1, estado_atual[1]);
    buf (state_bit2, estado_atual[2]);
    buf (state_bit3, estado_atual[3]);
    
    // Sinais intermediários para detecção de estados
    // Estado 1 (MOVER_PARA_ENCHIMENTO): 0001
    wire estado_1;
    wire not_s0, not_s1, not_s2, not_s3;
    not (not_s0, state_bit0);
    not (not_s1, state_bit1);
    not (not_s2, state_bit2);
    not (not_s3, state_bit3);
    and (estado_1, not_s3, not_s2, not_s1, state_bit0);
    
    // Estado 2 (AGUARDA_ESTEIRA_1): 0010
    wire estado_2;
    and (estado_2, not_s3, not_s2, state_bit1, not_s0);
    
    // Estado 3 (ENCHENDO): 0011
    wire estado_3;
    and (estado_3, not_s3, not_s2, state_bit1, state_bit0);
    
    // Estado 4 (AGUARDA_ENCHIMENTO): 0100
    wire estado_4;
    and (estado_4, not_s3, state_bit2, not_s1, not_s0);
    
    // Estado 5 (VEDANDO): 0101
    wire estado_5;
    and (estado_5, not_s3, state_bit2, not_s1, state_bit0);
    
    // Estado 6 (AGUARDA_VEDACAO): 0110
    wire estado_6;
    and (estado_6, not_s3, state_bit2, state_bit1, not_s0);
    
    // Estado 7 (MOVER_PARA_CQ): 0111
    wire estado_7;
    and (estado_7, not_s3, state_bit2, state_bit1, state_bit0);
    
    // Estado 8 (AGUARDA_ESTEIRA_2): 1000
    wire estado_8;
    and (estado_8, state_bit3, not_s2, not_s1, not_s0);
    
    // Estado 9 (VERIFICANDO_CQ): 1001
    wire estado_9;
    and (estado_9, state_bit3, not_s2, not_s1, state_bit0);
    
    // Estado 10 (AGUARDA_CQ): 1010
    wire estado_10;
    and (estado_10, state_bit3, not_s2, state_bit1, not_s0);
    
    // Estado 11 (MOVER_PARA_FINAL): 1011
    wire estado_11;
    and (estado_11, state_bit3, not_s2, state_bit1, state_bit0);
    
    // Estado 12 (AGUARDA_ESTEIRA_3): 1100
    wire estado_12;
    and (estado_12, state_bit3, state_bit2, not_s1, not_s0);
    
    // Estado 13 (CONTANDO_FINAL): 1101
    wire estado_13;
    and (estado_13, state_bit3, state_bit2, not_s1, state_bit0);
    
    // Saídas usando portas OR para combinar estados
    // cmd_mover_para_enchimento: estados 1 ou 2
    wire cmd_mover_ench_temp;
    or (cmd_mover_ench_temp, estado_1, estado_2);
    buf (cmd_mover_para_enchimento, cmd_mover_ench_temp);
    
    // cmd_encher: estados 3 ou 4
    wire cmd_encher_temp;
    or (cmd_encher_temp, estado_3, estado_4);
    buf (cmd_encher, cmd_encher_temp);
    
    // cmd_vedar: estados 5 ou 6
    wire cmd_vedar_temp;
    or (cmd_vedar_temp, estado_5, estado_6);
    buf (cmd_vedar, cmd_vedar_temp);
    
    // cmd_mover_para_cq: estados 7 ou 8
    wire cmd_mover_cq_temp;
    or (cmd_mover_cq_temp, estado_7, estado_8);
    buf (cmd_mover_para_cq, cmd_mover_cq_temp);
    
    // cmd_verificar_cq: estados 9 ou 10
    wire cmd_verificar_cq_temp;
    or (cmd_verificar_cq_temp, estado_9, estado_10);
    buf (cmd_verificar_cq, cmd_verificar_cq_temp);
    
    // cmd_mover_para_final: estados 11 ou 12
    wire cmd_mover_final_temp;
    or (cmd_mover_final_temp, estado_11, estado_12);
    buf (cmd_mover_para_final, cmd_mover_final_temp);
    
    // incrementar_duzia: estado 13 AND pulso_sensor_final
    wire incrementar_duzia_temp;
    and (incrementar_duzia_temp, estado_13, pulso_sensor_final);
    buf (incrementar_duzia, incrementar_duzia_temp);

endmodule

