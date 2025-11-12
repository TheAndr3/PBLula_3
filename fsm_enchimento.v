// ============================================================================
// Módulo: fsm_enchimento.v
// Descrição: FSM MOORE para controle da válvula de enchimento
//            A saída (VÁLVULA) depende apenas do estado
//            Imune a ruído no sensor de nível
// Tipo: Verilog COMPORTAMENTAL (FSM MOORE)
// ============================================================================

module fsm_enchimento (
    input wire clk,                      // Clock de 50MHz
    input wire reset,                    // Reset global
    input wire cmd_iniciar,              // Comando do mestre para iniciar enchimento
    input wire sensor_nivel,             // SW1 - Sensor de nível (1 = cheia)
    output reg valvula_ativa,            // LEDR[8] - Válvula de enchimento
    output reg tarefa_concluida          // Sinal de volta para o mestre
);

    // Estados da FSM
    localparam IDLE = 2'd0;
    localparam ENCHENDO = 2'd1;
    localparam CONCLUIDO = 2'd2;
    
    reg [1:0] estado_atual;
    
    // Lógica de transição de estados (SEQUENCIAL)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            estado_atual <= IDLE;
        end else begin
            case (estado_atual)
                IDLE: begin
                    if (cmd_iniciar) begin
                        estado_atual <= ENCHENDO;
                    end
                end
                
                ENCHENDO: begin
                    // Transição ocorre quando sensor de nível detecta garrafa cheia
                    if (sensor_nivel) begin
                        estado_atual <= CONCLUIDO;
                    end
                end
                
                CONCLUIDO: begin
                    // Aguarda o comando ser desligado para voltar ao IDLE
                    if (!cmd_iniciar) begin
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
    // LÓGICA MOORE: Saída depende APENAS do ESTADO
    // ========================================================================
    // A válvula permanece estável durante o estado ENCHENDO
    // Imune a flutuações no sensor_nivel (ruído)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            valvula_ativa <= 1'b0;
            tarefa_concluida <= 1'b0;
        end else begin
            case (estado_atual)
                IDLE: begin
                    valvula_ativa <= 1'b0;
                    tarefa_concluida <= 1'b0;
                end
                
                ENCHENDO: begin
                    valvula_ativa <= 1'b1;  // Válvula LIGADA
                    tarefa_concluida <= 1'b0;
                end
                
                CONCLUIDO: begin
                    valvula_ativa <= 1'b0;  // Válvula DESLIGADA
                    tarefa_concluida <= 1'b1;  // Sinaliza conclusão
                end
                
                default: begin
                    valvula_ativa <= 1'b0;
                    tarefa_concluida <= 1'b0;
                end
            endcase
        end
    end

endmodule

