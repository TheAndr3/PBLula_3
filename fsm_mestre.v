// ============================================================================
// Módulo: fsm_mestre.v
// Descrição: FSM MOORE - Sequenciador Principal (Mestre)
//            Coordena todas as FSMs escravas e controla o motor da esteira
//            Implementa ~20 estados para controle granular do processo
// Tipo: Verilog COMPORTAMENTAL (FSM MOORE)
// ============================================================================

module fsm_mestre (
    input wire clk,                          // Clock de 50MHz
    input wire reset,                        // Reset global
    input wire start,                        // Pulso do botão START (KEY0)
    input wire alarme_rolha,                 // Alarme de falta de rolha
    
    // Sensores de Posição
    input wire sensor_enchimento,            // SW[0]
    input wire sensor_vedacao,               // SW[5] (Novo)
    input wire sensor_cq,                    // SW[2]
    input wire sensor_descarte,              // SW[6] (Novo)
    input wire sensor_final,                 // SW[4]
    
    // Sinais das FSMs escravas
    input wire enchimento_concluido,         // Enchimento finalizado
    input wire vedacao_concluida,            // Vedação finalizada
    input wire cq_concluida,                 // Controle de qualidade finalizado
    input wire garrafa_aprovada,             // Garrafa foi aprovada no CQ
    
    // Comandos para FSMs escravas e Atuadores
    output wire motor_ativo,                 // LEDR[9] - Controle direto do motor
    output wire cmd_encher,                  // Comando para encher
    output wire cmd_vedar,                   // Comando para vedar
    output wire cmd_verificar_cq,            // Comando para verificar CQ
    output wire descarte_ativo,              // LEDR[6] - Ação de descarte (controlado pelo Mestre)
    
    // Sinal para contador de dúzias
    output wire incrementar_duzia            // Incrementa contador ao final
);

    // Estados da FSM Mestre (Codificação One-Hot Simplificada ou Binária)
    // Usando 5 bits para cobrir > 16 estados
    localparam IDLE = 5'd0;
    localparam MOVER_PARA_ENCHIMENTO = 5'd1;
    localparam POSICIONAMENTO_ENCHIMENTO = 5'd2;
    localparam COMANDO_ENCHIMENTO = 5'd3;
    localparam AGUARDA_ENCHIMENTO = 5'd4;
    localparam MOVER_PARA_VEDACAO = 5'd5;
    localparam POSICIONAMENTO_VEDACAO = 5'd6;
    localparam COMANDO_VEDACAO = 5'd7;
    localparam AGUARDA_VEDACAO = 5'd8;
    localparam VERIFICAR_ROLHAS = 5'd9;
    localparam MOVER_PARA_CQ = 5'd10;
    localparam POSICIONAMENTO_CQ = 5'd11;
    localparam COMANDO_CQ = 5'd12;
    localparam AGUARDA_CQ = 5'd13;
    localparam DECISAO_CQ = 5'd14;
    localparam MOVER_PARA_DESCARTE = 5'd15;
    localparam ACAO_DESCARTE = 5'd16;
    localparam MOVER_PARA_FINAL = 5'd17;
    localparam POSICIONAMENTO_FINAL = 5'd18;
    localparam CONTANDO_FINAL = 5'd19;
    localparam PARADO_SEM_ROLHA = 5'd20;
    
    reg [4:0] estado_atual;
    reg [4:0] estado_anterior; // Para retomar após pausa sem rolha
    
    // Timer para ação de descarte (0.5s)
    reg [25:0] timer;
    parameter TEMPO_DESCARTE = 26'd25000000; // 0.5s a 50MHz
    reg tempo_descarte_completo;
    
    // Sincronização do sensor final para contagem
    reg sensor_final_prev;
    wire pulso_sensor_final;
    wire not_sensor_final_prev;
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
            estado_anterior <= IDLE;
            timer <= 0;
            tempo_descarte_completo <= 1'b0;
        end else begin
            // Timer logic
            if (estado_atual == ACAO_DESCARTE) begin
                timer <= timer + 1;
                if (timer >= TEMPO_DESCARTE) begin
                    tempo_descarte_completo <= 1'b1;
                end
            end else begin
                timer <= 0;
                tempo_descarte_completo <= 1'b0;
            end
            
            case (estado_atual)
                IDLE: begin
                    if (start) begin
                        if (alarme_rolha) begin
                            estado_anterior <= MOVER_PARA_ENCHIMENTO; // Tentativa inicial
                            estado_atual <= PARADO_SEM_ROLHA;
                        end else begin
                            estado_atual <= MOVER_PARA_ENCHIMENTO;
                        end
                    end
                end
                
                // --- Enchimento ---
                MOVER_PARA_ENCHIMENTO: begin
                    if (sensor_enchimento) estado_atual <= POSICIONAMENTO_ENCHIMENTO;
                end
                
                POSICIONAMENTO_ENCHIMENTO: begin
                    // Pequeno delay ou verificação extra poderia ser aqui
                    estado_atual <= COMANDO_ENCHIMENTO;
                end
                
                COMANDO_ENCHIMENTO: begin
                    estado_atual <= AGUARDA_ENCHIMENTO;
                end
                
                AGUARDA_ENCHIMENTO: begin
                    if (enchimento_concluido) begin
                        estado_atual <= MOVER_PARA_VEDACAO;
                    end
                end
                
                // --- Vedação ---
                MOVER_PARA_VEDACAO: begin
                    // Verifica rolha antes/durante movimento
                    if (alarme_rolha) begin
                        estado_anterior <= MOVER_PARA_VEDACAO;
                        estado_atual <= PARADO_SEM_ROLHA;
                    end else if (sensor_vedacao) begin
                        estado_atual <= POSICIONAMENTO_VEDACAO;
                    end
                end
                
                POSICIONAMENTO_VEDACAO: begin
                    estado_atual <= COMANDO_VEDACAO;
                end
                
                COMANDO_VEDACAO: begin
                    estado_atual <= AGUARDA_VEDACAO;
                end
                
                AGUARDA_VEDACAO: begin
                    if (vedacao_concluida) begin
                        estado_atual <= VERIFICAR_ROLHAS;
                    end
                end
                
                VERIFICAR_ROLHAS: begin
                    // Pós-vedação check
                    if (alarme_rolha) begin
                        estado_anterior <= MOVER_PARA_CQ;
                        estado_atual <= PARADO_SEM_ROLHA;
                    end else begin
                        estado_atual <= MOVER_PARA_CQ;
                    end
                end
                
                // --- CQ ---
                MOVER_PARA_CQ: begin
                    if (sensor_cq) estado_atual <= POSICIONAMENTO_CQ;
                end
                
                POSICIONAMENTO_CQ: begin
                    estado_atual <= COMANDO_CQ;
                end
                
                COMANDO_CQ: begin
                    estado_atual <= AGUARDA_CQ;
                end
                
                AGUARDA_CQ: begin
                    if (cq_concluida) begin
                        estado_atual <= DECISAO_CQ;
                    end
                end
                
                DECISAO_CQ: begin
                    if (garrafa_aprovada) begin
                        estado_atual <= MOVER_PARA_FINAL;
                    end else begin
                        estado_atual <= MOVER_PARA_DESCARTE;
                    end
                end
                
                // --- Descarte ---
                MOVER_PARA_DESCARTE: begin
                    if (sensor_descarte) estado_atual <= ACAO_DESCARTE;
                end
                
                ACAO_DESCARTE: begin
                    if (tempo_descarte_completo) begin
                        // Após descarte, volta para início
                        estado_atual <= MOVER_PARA_ENCHIMENTO;
                    end
                end
                
                // --- Final ---
                MOVER_PARA_FINAL: begin
                    if (sensor_final) estado_atual <= POSICIONAMENTO_FINAL;
                end
                
                POSICIONAMENTO_FINAL: begin
                    estado_atual <= CONTANDO_FINAL;
                end
                
                CONTANDO_FINAL: begin
                    // Aguarda pulso do sensor final (garantir contagem)
                    // Como já chegamos no sensor_final, o pulso já deve ter ocorrido ou está alto
                    // Simplificação: conta e volta
                    estado_atual <= MOVER_PARA_ENCHIMENTO;
                end
                
                // --- Tratamento de Erro ---
                PARADO_SEM_ROLHA: begin
                    if (!alarme_rolha) begin
                        // Retoma de onde parou
                        estado_atual <= estado_anterior;
                    end
                end
                
                default: estado_atual <= IDLE;
            endcase
        end
    end
    
    // ========================================================================
    // LÓGICA MOORE: Saídas dependem APENAS do ESTADO (ESTRUTURAL - PORTAS)
    // ========================================================================
    // Decodificação One-Hot dos estados para facilitar lógica estrutural
    // 5 bits de estado => 21 estados possíveis (0 a 20)
    
    // Bits do estado
    wire s0, s1, s2, s3, s4;
    buf (s0, estado_atual[0]);
    buf (s1, estado_atual[1]);
    buf (s2, estado_atual[2]);
    buf (s3, estado_atual[3]);
    buf (s4, estado_atual[4]);
    
    // Inversão dos bits
    wire ns0, ns1, ns2, ns3, ns4;
    not (ns0, s0);
    not (ns1, s1);
    not (ns2, s2);
    not (ns3, s3);
    not (ns4, s4);
    
    // Decodificação dos Estados Relevantes para Saídas
    
    // MOVER_PARA_ENCHIMENTO (1 = 00001)
    wire st_mover_ench;
    and (st_mover_ench, ns4, ns3, ns2, ns1, s0);
    
    // COMANDO_ENCHIMENTO (3 = 00011)
    wire st_cmd_ench;
    and (st_cmd_ench, ns4, ns3, ns2, s1, s0);
    
    // AGUARDA_ENCHIMENTO (4 = 00100)
    wire st_wait_ench;
    and (st_wait_ench, ns4, ns3, s2, ns1, ns0);
    
    // MOVER_PARA_VEDACAO (5 = 00101)
    wire st_mover_ved;
    and (st_mover_ved, ns4, ns3, s2, ns1, s0);
    
    // COMANDO_VEDACAO (7 = 00111)
    wire st_cmd_ved;
    and (st_cmd_ved, ns4, ns3, s2, s1, s0);
    
    // AGUARDA_VEDACAO (8 = 01000)
    wire st_wait_ved;
    and (st_wait_ved, ns4, s3, ns2, ns1, ns0);
    
    // MOVER_PARA_CQ (10 = 01010)
    wire st_mover_cq;
    and (st_mover_cq, ns4, s3, ns2, s1, ns0);
    
    // COMANDO_CQ (12 = 01100)
    wire st_cmd_cq;
    and (st_cmd_cq, ns4, s3, s2, ns1, ns0);
    
    // AGUARDA_CQ (13 = 01101)
    wire st_wait_cq;
    and (st_wait_cq, ns4, s3, s2, ns1, s0);
    
    // MOVER_PARA_DESCARTE (15 = 01111)
    wire st_mover_desc;
    and (st_mover_desc, ns4, s3, s2, s1, s0);
    
    // ACAO_DESCARTE (16 = 10000)
    wire st_acao_desc;
    and (st_acao_desc, s4, ns3, ns2, ns1, ns0);
    
    // MOVER_PARA_FINAL (17 = 10001)
    wire st_mover_final;
    and (st_mover_final, s4, ns3, ns2, ns1, s0);
    
    // CONTANDO_FINAL (19 = 10011)
    wire st_cnt_final;
    and (st_cnt_final, s4, ns3, ns2, s1, s0);
    
    // --- Definição das Saídas ---
    
    // motor_ativo: Liga nos estados de movimento (1, 5, 10, 15, 17)
    wire motor_tmp1, motor_tmp2, motor_tmp3, motor_out;
    or (motor_tmp1, st_mover_ench, st_mover_ved);
    or (motor_tmp2, st_mover_cq, st_mover_desc);
    or (motor_tmp3, motor_tmp1, motor_tmp2);
    or (motor_out, motor_tmp3, st_mover_final);
    buf (motor_ativo, motor_out);
    
    // cmd_encher: Estados 3 ou 4 (Comando + Espera)
    wire cmd_ench_out;
    or (cmd_ench_out, st_cmd_ench, st_wait_ench);
    buf (cmd_encher, cmd_ench_out);
    
    // cmd_vedar: Estados 7 ou 8
    wire cmd_ved_out;
    or (cmd_ved_out, st_cmd_ved, st_wait_ved);
    buf (cmd_vedar, cmd_ved_out);
    
    // cmd_verificar_cq: Estados 12 ou 13
    wire cmd_cq_out;
    or (cmd_cq_out, st_cmd_cq, st_wait_cq);
    buf (cmd_verificar_cq, cmd_cq_out);
    
    // descarte_ativo: Estado 16 (ACAO_DESCARTE)
    buf (descarte_ativo, st_acao_desc);
    
    // incrementar_duzia: Estado 19 AND pulso_sensor_final
    // Na verdade, apenas estar no estado 19 já pode ser usado se quisermos contar por ciclo
    // Mas para ser preciso, usamos o estado. Como o estado é de um ciclo ou espera,
    // vamos usar apenas o estado_cnt_final para ativar, pois o pulso pode ter passado.
    // Porém, para evitar múltipla contagem se ficar parado, idealmente seria borda.
    // Mas como a FSM sai do estado imediatamente (ver always block), podemos usar o estado.
    buf (incrementar_duzia, st_cnt_final);

endmodule
