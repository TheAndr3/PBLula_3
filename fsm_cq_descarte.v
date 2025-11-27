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
    input wire start,            // Comando para começar o controle de qualidade
    input wire aprovado,                // SW2 - Sensor de posição CQ
    input wire reprovado,              // KEY[0] para confirmar decisão
	 input wire garrafa_concluida,
    output wire descarte_ativo,          // LEDR[6] - Atuador de descarte
    output wire garrafa_aprovada,        // Sinal para incrementar contador de dúzias
    output wire tarefa_concluida,         // Sinal de volta para o mestre
	 output wire estado_idle
);

    // Estados da FSM
    localparam IDLE = 2'd0;
    localparam DESCARTANDO = 2'd1;
    localparam APROVADO = 2'd2;
    
    reg [1:0] estado_atual;
    
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
		  
            case (estado_atual)
                IDLE: begin
                    timer <= 0;
						  tempo_completo <= 1'b0;
                    if (start && reprovado && !aprovado) begin
                        estado_atual <= DESCARTANDO;
                    end
						  if (start && aprovado && !reprovado) begin
                        estado_atual <= APROVADO;
                    end
						  
                end
					 
                DESCARTANDO: begin
							timer <= timer+1;
							
							if (timer >= TEMPO_DESCARTE) begin
								 tempo_completo <= 1'b1;
							end
                    // Transição após o tempo de descarte
                    if (garrafa_concluida && tempo_completo) begin
                        estado_atual <= IDLE;
                    end
                end
                
                APROVADO: begin
                    // Aguarda o comando ser desligado para voltar ao IDLE
                    if (garrafa_concluida) begin
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
    wire state_bit0, state_bit1;
    buf (state_bit0, estado_atual[0]);
    buf (state_bit1, estado_atual[1]);
    
    // Sinais intermediários
    wire not_state_bit0, not_state_bit1;
    not (not_state_bit0, state_bit0);
    not (not_state_bit1, state_bit1);
    
    // Detecção de estados específicos
	 and (estado_idle, not_state_bit1, not_state_bit0);
    // DESCARTANDO (01): state_bit2=0, state_bit1=1, state_bit0=1
    wire estado_descartando;
    and (estado_descartando, not_state_bit1, state_bit0);
    
    // APROVADO (10): state_bit2=1, state_bit1=0, state_bit0=0
    wire estado_aprovado;
    and (estado_aprovado, state_bit1, not_state_bit0);
    
    // Saídas
    // descarte_ativo = 1 quando estado_atual == DESCARTANDO (011)
    buf (descarte_ativo, estado_descartando);
	 wire descarte_conc;
	 or (descarte_conc, tempo_completo, estado_descartando);
    
    // tarefa_concluida = 1 quando estado_atual == APROVADO (100)
    or (tarefa_concluida, estado_aprovado, descarte_conc);
    
    // garrafa_aprovada = 1 quando estado_atual == APROVADO (100)
    buf (garrafa_aprovada, estado_aprovado);

endmodule

