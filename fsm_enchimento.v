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
	 input wire garrafa_concluida,
	 input wire led1,
	 input wire led2,
	 output wire esteira,						// LEDR[9] - Motor ligado
    output wire valvula_ativa,           // LEDR[8] - Válvula de enchimento
    output wire tarefa_concluida         // Sinal de volta para o mestre
);

    // Estados da FSM
    localparam IDLE = 2'b00;
    localparam ENCHENDO = 2'b01;
    localparam CONCLUIDO = 2'b10;
	 localparam ESTEIRA = 2'b11;
	 
	 reg [25:0] tempo_motor;
	 parameter TEMPO_ESTEIRA = 26'd50000000;
	 reg motor;
    
    reg [1:0] estado_atual;
    
    // Lógica de transição de estados (SEQUENCIAL)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            estado_atual <= IDLE;
        end else begin
            case (estado_atual)
                IDLE: begin
							tempo_motor <= 0;
							motor <= 1'b0;
                    if (cmd_iniciar) begin
                        estado_atual <= ESTEIRA;
                    end
                end
					 
					 ESTEIRA: begin
							motor <= 1'b1;
							tempo_motor <= tempo_motor + 1;
							
							if (tempo_motor >= TEMPO_ESTEIRA) begin
								motor <= 1'b0;
								tempo_motor <= 0;
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
                    if (!cmd_iniciar && garrafa_concluida) begin
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
    // Extração dos bits do estado (2 bits: estado_atual[1:0])
    // Codificação: IDLE=00, ENCHENDO=01, CONCLUIDO=10
    wire state_bit0, state_bit1;
    buf (state_bit0, estado_atual[0]);
    buf (state_bit1, estado_atual[1]);
	 
	 buf (led1, state_bit0);
	 buf (led2, state_bit1);
    
    // Sinais intermediários
    wire not_state_bit0, not_state_bit1;
    not (not_state_bit0, state_bit0);
    not (not_state_bit1, state_bit1);
	 
	 // Ativação do motor
	 buf (esteira, motor);
    
    // valvula_ativa = 1 quando estado_atual == ENCHENDO (01)
    // Ou seja: state_bit1=0 AND state_bit0=1
    and (valvula_ativa, not_state_bit1, state_bit0);
    
    // tarefa_concluida = 1 quando estado_atual == CONCLUIDO (10)
    // Ou seja: state_bit1=1 AND state_bit0=0
    and (tarefa_concluida, state_bit1, not_state_bit0);
	 

endmodule

