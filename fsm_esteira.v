// ============================================================================
// Módulo: fsm_esteira.v
// Descrição: FSM MOORE para controle do motor da esteira
//            A saída (MOTOR) depende apenas do estado atual
//            Conversão de Mealy para Moore conforme requisitos
// Tipo: Verilog HÍBRIDO (Comportamental para transições, Estrutural para saídas)
// ============================================================================

module fsm_esteira (
    input wire clk,                      // Clock de 50MHz
    input wire reset,                    // Reset global
    input wire cmd_mover,                // Comando do mestre para iniciar movimento
    input wire sensor_destino,           // Sensor do destino (SW0, SW2, SW4)
    input wire alarme_rolha,             // Alarme de falta de rolha (para o motor)
    output wire motor_ativo,             // LEDR[9] - Motor (saída MOORE)
    output wire tarefa_concluida         // Sinal de volta para o mestre
);

    // Estados da FSM
    // Codificação: IDLE=00, MOVENDO=01, PARADO=10
    localparam IDLE = 2'd0;
    localparam MOVENDO = 2'd1;
    localparam PARADO = 2'd2;
    
    reg [1:0] estado_atual;
    
    // Sinais internos para os bits do estado
    wire state_bit0;  // estado_atual[0]
    wire state_bit1;  // estado_atual[1]
    
    // Extração dos bits do estado
    buf (state_bit0, estado_atual[0]);
    buf (state_bit1, estado_atual[1]);
    
    // Lógica de transição de estados (SEQUENCIAL - COMPORTAMENTAL)
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
    // LÓGICA MOORE: Saídas dependem APENAS do ESTADO (ESTRUTURAL - PORTAS)
    // ========================================================================
    // motor_ativo = 1 quando estado_atual == MOVENDO (01)
    // Ou seja: state_bit1=0 AND state_bit0=1
    wire not_state_bit1;
    wire motor_ativo_temp;
    
    not (not_state_bit1, state_bit1);
    and (motor_ativo_temp, not_state_bit1, state_bit0);
    
    // Lógica MOORE Pura: Motor ligado APENAS se estiver no estado MOVENDO
    // Se houver alarme, a transição de estado (always) cuidará de ir para PARADO
    // no próximo ciclo de clock, e então o motor desligará automaticamente
    buf (motor_ativo, motor_ativo_temp);
    
    // tarefa_concluida = 1 quando estado_atual == PARADO (10)
    // Ou seja: state_bit1=1 AND state_bit0=0
    wire not_state_bit0;
    not (not_state_bit0, state_bit0);
    and (tarefa_concluida, state_bit1, not_state_bit0);

endmodule

