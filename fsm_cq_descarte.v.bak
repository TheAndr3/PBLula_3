// ============================================================================
// Módulo: fsm_cq_descarte.v
// Descrição: FSM MOORE para controle de qualidade e descarte
//            Verifica se a garrafa foi aprovada ou reprovada
//            Aciona o descarte se reprovada
// Tipo: Verilog COMPORTAMENTAL (FSM MOORE)
// ============================================================================

module fsm_cq_descarte (
    input wire clk,                      // Clock de 50MHz
    input wire reset,                    // Reset global
    input wire cmd_verificar,            // Comando do mestre para verificar CQ
    input wire sensor_cq,                // SW2 - Sensor de posição CQ
    input wire pulso_start,              // KEY[0] para confirmar decisão
    input wire resultado_cq,             // SW3 - Resultado CQ (0=Reprovado, 1=Aprovado)
    output wire descarte_ativo,          // LEDR[6] - Atuador de descarte
    output wire garrafa_aprovada,        // Sinal para incrementar contador de dúzias
    output wire tarefa_concluida         // Sinal de volta para o mestre
);

    // Estados da FSM
    localparam IDLE = 3'd0;
    localparam VERIFICANDO = 3'd1;
    localparam AGUARDA_DECISAO = 3'd2;  // Novo estado de pausa
    localparam DESCARTANDO = 3'd3;
    localparam APROVADO = 3'd4;
    
    reg [2:0] estado_atual;
    
    // Timer para simular o tempo de descarte (0.5 segundos)
    reg [25:0] timer;
    parameter TEMPO_DESCARTE = 26'd25000000; // 0.5s a 50MHz
    reg tempo_completo;
    
    // Lógica de transição de estados (SEQUENCIAL - COMPORTAMENTAL)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            estado_atual <= IDLE;
            timer <= 0;
            tempo_completo <= 1'b0;
        end else begin
            // Atualiza sinal do timer
            if (timer >= TEMPO_DESCARTE) begin
                tempo_completo <= 1'b1;
            end else begin
                tempo_completo <= 1'b0;
            end
            
            case (estado_atual)
                IDLE: begin
                    timer <= 0;
                    if (cmd_verificar) begin
                        estado_atual <= VERIFICANDO;
                    end
                end
                
                VERIFICANDO: begin
                    // Aguarda o sensor CQ detectar a garrafa
                    if (sensor_cq) begin
                        estado_atual <= AGUARDA_DECISAO; // Pausa para o operador decidir
                    end
                end
                
                AGUARDA_DECISAO: begin
                    // Aguarda o operador pressionar START para confirmar
                    if (pulso_start) begin
                        // Verifica o resultado do CQ
                        if (resultado_cq == 1'b0) begin
                            // Reprovado - vai para descarte
                            estado_atual <= DESCARTANDO;
                        end else begin
                            // Aprovado - garrafa segue
                            estado_atual <= APROVADO;
                        end
                    end
                end
                
                DESCARTANDO: begin
                    timer <= timer + 1;
                    // Transição após o tempo de descarte
                    if (tempo_completo) begin
                        estado_atual <= IDLE;
                    end
                end
                
                APROVADO: begin
                    // Aguarda o comando ser desligado para voltar ao IDLE
                    if (!cmd_verificar) begin
                        estado_atual <= IDLE;
                    end
                end
                
                default: begin
                    estado_atual <= IDLE;
                    timer <= 0;
                end
            endcase
        end
    end
    
    // ========================================================================
    // LÓGICA MOORE: Saídas dependem APENAS do ESTADO (ESTRUTURAL - PORTAS)
    // ========================================================================
    // Extração dos bits do estado (3 bits: estado_atual[2:0])
    // Codificação: IDLE=000, VERIFICANDO=001, AGUARDA_DECISAO=010, DESCARTANDO=011, APROVADO=100
    wire state_bit0, state_bit1, state_bit2;
    buf (state_bit0, estado_atual[0]);
    buf (state_bit1, estado_atual[1]);
    buf (state_bit2, estado_atual[2]);
    
    // Sinais intermediários
    wire not_state_bit0, not_state_bit1, not_state_bit2;
    not (not_state_bit0, state_bit0);
    not (not_state_bit1, state_bit1);
    not (not_state_bit2, state_bit2);
    
    // Detecção de estados específicos
    // DESCARTANDO (011): state_bit2=0, state_bit1=1, state_bit0=1
    wire estado_descartando;
    and (estado_descartando, not_state_bit2, state_bit1, state_bit0);
    
    // APROVADO (100): state_bit2=1, state_bit1=0, state_bit0=0
    wire estado_aprovado;
    and (estado_aprovado, state_bit2, not_state_bit1, not_state_bit0);
    
    // Saídas
    // descarte_ativo = 1 quando estado_atual == DESCARTANDO (011)
    buf (descarte_ativo, estado_descartando);
    
    // tarefa_concluida = 1 quando estado_atual == APROVADO (100)
    buf (tarefa_concluida, estado_aprovado);
    
    // garrafa_aprovada = 1 quando estado_atual == APROVADO (100)
    buf (garrafa_aprovada, estado_aprovado);

endmodule

