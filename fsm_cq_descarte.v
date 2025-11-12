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
    input wire resultado_cq,             // SW3 - Resultado CQ (0=Reprovado, 1=Aprovado)
    output reg descarte_ativo,           // LEDR[6] - Atuador de descarte
    output reg garrafa_aprovada,         // Sinal para incrementar contador de dúzias
    output reg tarefa_concluida          // Sinal de volta para o mestre
);

    // Estados da FSM
    localparam IDLE = 2'd0;
    localparam VERIFICANDO = 2'd1;
    localparam DESCARTANDO = 2'd2;
    localparam APROVADO = 2'd3;
    
    reg [1:0] estado_atual;
    
    // Timer para simular o tempo de descarte (0.5 segundos)
    reg [25:0] timer;
    parameter TEMPO_DESCARTE = 26'd25000000; // 0.5s a 50MHz
    wire tempo_completo;
    
    assign tempo_completo = (timer >= TEMPO_DESCARTE);
    
    // Lógica de transição de estados (SEQUENCIAL)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            estado_atual <= IDLE;
            timer <= 0;
        end else begin
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
    // LÓGICA MOORE: Saída depende APENAS do ESTADO
    // ========================================================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            descarte_ativo <= 1'b0;
            tarefa_concluida <= 1'b0;
            garrafa_aprovada <= 1'b0;
        end else begin
            case (estado_atual)
                IDLE: begin
                    descarte_ativo <= 1'b0;
                    tarefa_concluida <= 1'b0;
                    garrafa_aprovada <= 1'b0;
                end
                
                VERIFICANDO: begin
                    descarte_ativo <= 1'b0;
                    tarefa_concluida <= 1'b0;
                    garrafa_aprovada <= 1'b0;
                end
                
                DESCARTANDO: begin
                    descarte_ativo <= 1'b1;  // Descarte ATIVO
                    tarefa_concluida <= 1'b0;
                    garrafa_aprovada <= 1'b0;
                end
                
                APROVADO: begin
                    descarte_ativo <= 1'b0;
                    tarefa_concluida <= 1'b1;  // Sinaliza conclusão
                    garrafa_aprovada <= 1'b1;  // Garrafa aprovada
                end
                
                default: begin
                    descarte_ativo <= 1'b0;
                    tarefa_concluida <= 1'b0;
                    garrafa_aprovada <= 1'b0;
                end
            endcase
        end
    end

endmodule

