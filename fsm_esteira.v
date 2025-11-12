// ============================================================================
// Módulo: fsm_esteira.v
// Descrição: FSM MEALY para controle do motor da esteira
//            A saída (MOTOR) reage instantaneamente aos sensores
//            Garante parada precisa quando sensor é ativado
// Tipo: Verilog COMPORTAMENTAL (FSM MEALY)
// ============================================================================

module fsm_esteira (
    input wire clk,                      // Clock de 50MHz
    input wire reset,                    // Reset global
    input wire cmd_mover,                // Comando do mestre para iniciar movimento
    input wire sensor_destino,           // Sensor do destino (SW0, SW2, SW4)
    input wire alarme_rolha,             // Alarme de falta de rolha (para o motor)
    output reg motor_ativo,              // LEDR[9] - Motor (saída MEALY)
    output reg tarefa_concluida          // Sinal de volta para o mestre
);

    // Estados da FSM
    localparam IDLE = 2'd0;
    localparam MOVENDO = 2'd1;
    localparam PARADO = 2'd2;
    
    reg [1:0] estado_atual;
    
    // Lógica de transição de estados (SEQUENCIAL)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            estado_atual <= IDLE;
        end else begin
            case (estado_atual)
                IDLE: begin
                    if (cmd_mover && !alarme_rolha) begin
                        estado_atual <= MOVENDO;
                    end
                end
                
                MOVENDO: begin
                    // Transição ocorre quando sensor é ativado OU alarme é acionado
                    if (sensor_destino || alarme_rolha) begin
                        estado_atual <= PARADO;
                    end
                end
                
                PARADO: begin
                    // Aguarda o comando ser desligado para voltar ao IDLE
                    if (!cmd_mover) begin
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
    // LÓGICA MEALY: Saída depende do ESTADO E DA ENTRADA
    // ========================================================================
    // CRÍTICO: O motor deve parar INSTANTANEAMENTE quando o sensor é ativado
    // Se usássemos Moore, o motor continuaria ligado por 1 ciclo de clock a mais
    always @(*) begin
        // Motor está ligado SOMENTE se:
        // 1. Está no estado MOVENDO
        // 2. Sensor ainda NÃO foi ativado (sensor_destino == 0)
        // 3. Alarme de rolha NÃO está ativo
        motor_ativo = (estado_atual == MOVENDO) && 
                      (!sensor_destino) && 
                      (!alarme_rolha);
    end
    
    // Lógica de saída para tarefa_concluida (MOORE - depende só do estado)
    always @(*) begin
        tarefa_concluida = (estado_atual == PARADO);
    end

endmodule

