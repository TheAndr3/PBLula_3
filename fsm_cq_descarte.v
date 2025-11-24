// ============================================================================
// Módulo: fsm_cq_descarte.v
// Descrição: FSM MOORE para controle de qualidade
//            Verifica se a garrafa foi aprovada ou reprovada pelo operador
//            Inclui timer de inspeção para evitar decisões acidentais
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
    localparam PAUSA_INSPECAO = 3'd2;   // Novo estado: atraso para inspeção
    localparam AGUARDA_DECISAO = 3'd3;
    localparam DECISAO_TOMADA = 3'd4;
    
    reg [2:0] estado_atual;
    reg resultado_armazenado; // Armazena o resultado da decisão
    
    // Timer para simular tempo de inspeção da máquina (5 segundos)
    reg [27:0] timer;
    parameter TEMPO_INSPECAO = 28'd250000000; // 5.0s a 50MHz
    reg tempo_inspecao_completo;
    
    // Lógica de transição de estados (SEQUENCIAL)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            estado_atual <= IDLE;
            resultado_armazenado <= 1'b0;
            timer <= 0;
            tempo_inspecao_completo <= 1'b0;
        end else begin
            // Lógica do Timer
            if (estado_atual == PAUSA_INSPECAO) begin
                timer <= timer + 1;
                if (timer >= TEMPO_INSPECAO) begin
                    tempo_inspecao_completo <= 1'b1;
                end
            end else begin
                timer <= 0;
                tempo_inspecao_completo <= 1'b0;
            end
            
            case (estado_atual)
                IDLE: begin
                    if (cmd_verificar) begin
                        estado_atual <= VERIFICANDO;
                    end
                    resultado_armazenado <= 1'b0; // Reset do resultado
                end
                
                VERIFICANDO: begin
                    // Aguarda o sensor CQ detectar a garrafa
                    if (sensor_cq) begin
                        estado_atual <= PAUSA_INSPECAO; // Inicia inspeção
                    end
                end
                
                PAUSA_INSPECAO: begin
                    // Aguarda tempo de inspeção visual/máquina
                    if (tempo_inspecao_completo) begin
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
    // IDLE=000, VERIFICANDO=001, PAUSA=010, AGUARDA=011, TOMADA=100
    wire state_bit0, state_bit1, state_bit2;
    buf (state_bit0, estado_atual[0]);
    buf (state_bit1, estado_atual[1]);
    buf (state_bit2, estado_atual[2]);
    
    wire ns0, ns1, ns2;
    not (ns0, state_bit0);
    not (ns1, state_bit1);
    not (ns2, state_bit2);
    
    // tarefa_concluida = 1 quando estado_atual == DECISAO_TOMADA (100)
    and (tarefa_concluida, state_bit2, ns1, ns0);
    
    // garrafa_aprovada = 1 quando (estado_atual == DECISAO_TOMADA) AND (resultado_armazenado == 1)
    wire res_cq;
    buf (res_cq, resultado_armazenado);
    and (garrafa_aprovada, tarefa_concluida, res_cq);

endmodule
