// ============================================================================
// Módulo: fsm_cq_descarte.v
// Descrição: FSM MOORE para controle de qualidade
//            Verifica se a garrafa foi aprovada ou reprovada pelo operador
//            Apenas reporta a decisão; o descarte é feito pelo Mestre
// Tipo: Verilog COMPORTAMENTAL (FSM MOORE)
// ============================================================================

module fsm_cq_descarte (
    input wire clk,                      // Clock de 50MHz
    input wire reset,                    // Reset global
    input wire cmd_verificar,            // Comando do mestre para verificar CQ
    input wire sensor_cq,                // SW2 - Sensor de posição CQ
    input wire pulso_start,              // KEY[0] para confirmar decisão
    input wire resultado_cq,             // SW3 - Resultado CQ (0=Reprovado, 1=Aprovado)
    output wire garrafa_aprovada,        // 1 = Aprovada, 0 = Reprovada
    output wire tarefa_concluida         // Sinal de volta para o mestre
);

    // Estados da FSM
    localparam IDLE = 3'd0;
    localparam VERIFICANDO = 3'd1;
    localparam AGUARDA_DECISAO = 3'd2;
    localparam DECISAO_TOMADA = 3'd3;
    
    reg [2:0] estado_atual;
    reg resultado_armazenado; // Armazena o resultado da decisão
    
    // Lógica de transição de estados (SEQUENCIAL)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            estado_atual <= IDLE;
            resultado_armazenado <= 1'b0;
        end else begin
            case (estado_atual)
                IDLE: begin
                    if (cmd_verificar) begin
                        estado_atual <= VERIFICANDO;
                    end
                    resultado_armazenado <= 1'b0; // Reset do resultado
                end
                
                VERIFICANDO: begin
                    // Aguarda o sensor CQ detectar a garrafa (se já estiver lá, passa direto)
                    if (sensor_cq) begin
                        estado_atual <= AGUARDA_DECISAO;
                    end
                end
                
                AGUARDA_DECISAO: begin
                    // Aguarda o operador pressionar START para confirmar
                    if (pulso_start) begin
                        // Captura a decisão
                        resultado_armazenado <= resultado_cq;
                        estado_atual <= DECISAO_TOMADA;
                    end
                end
                
                DECISAO_TOMADA: begin
                    // Aguarda o comando ser desligado para voltar ao IDLE
                    if (!cmd_verificar) begin
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
    // LÓGICA MOORE: Saídas dependem APENAS do ESTADO (ESTRUTURAL - PORTAS)
    // ========================================================================
    // Extração dos bits do estado
    // IDLE=000, VERIFICANDO=001, AGUARDA_DECISAO=010, DECISAO_TOMADA=011
    wire state_bit0, state_bit1;
    buf (state_bit0, estado_atual[0]);
    buf (state_bit1, estado_atual[1]);
    
    // tarefa_concluida = 1 quando estado_atual == DECISAO_TOMADA (011)
    and (tarefa_concluida, state_bit1, state_bit0);
    
    // garrafa_aprovada = 1 quando (estado_atual == DECISAO_TOMADA) AND (resultado_armazenado == 1)
    // Nota: resultado_armazenado é um reg, mas usado aqui como entrada para lógica combinacional
    // Para ser puramente estrutural nas saídas, usamos buf/and
    wire res_cq;
    buf (res_cq, resultado_armazenado);
    and (garrafa_aprovada, tarefa_concluida, res_cq);

endmodule
