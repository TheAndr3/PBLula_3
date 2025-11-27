// ============================================================================
// Módulo: fsm_vedacao.v
// Descrição: FSM MOORE para controle do atuador de vedação
//            A saída (VEDAÇÃO) depende apenas do estado
//            Gera sinal para decrementar contador de rolhas
// Tipo: Verilog COMPORTAMENTAL (FSM MOORE)
// ============================================================================

module fsm_vedacao (
    input wire clk,                      // Clock de 50MHz
    input wire reset,                    // Reset global
    input wire cmd_iniciar,              // Comando do mestre para iniciar vedação
    input wire alarme_rolha,             // Alarme de falta de rolha
	 input wire cq_concluido,
    output wire vedacao_ativa,           // LEDR[7] - Atuador de vedação
    output wire decrementar_rolha,       // Sinal para decrementar contador
    output wire tarefa_concluida         // Sinal de volta para o mestre
);

    // Estados da FSM
    localparam IDLE = 2'd0;
    localparam VEDANDO = 2'd1;
    localparam CONCLUIDO = 2'd2;
    
    reg [1:0] estado_atual;
    
    // Timer para simular o tempo de vedação (0.5 segundos)
    reg [25:0] timer;
    parameter TEMPO_VEDACAO = 26'd25000000; // 0.5s a 50MHz
    reg tempo_completo;
    reg timer_igual_um;  // Sinal interno para detectar quando timer == 1
    
    // Lógica de transição de estados (SEQUENCIAL - COMPORTAMENTAL)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            estado_atual <= IDLE;
            timer <= 0;
            tempo_completo <= 1'b0;
            timer_igual_um <= 1'b0;
        end else begin
            // Atualiza sinais do timer
            if (timer >= TEMPO_VEDACAO) begin
                tempo_completo <= 1'b1;
            end else begin
                tempo_completo <= 1'b0;
            end
            
            if (timer == 26'd1) begin
                timer_igual_um <= 1'b1;
            end else begin
                timer_igual_um <= 1'b0;
            end
            
            case (estado_atual)
                IDLE: begin
                    timer <= 0;
                    if (cmd_iniciar && !alarme_rolha) begin
                        estado_atual <= VEDANDO;
                    end
                end
                
                VEDANDO: begin
                    timer <= timer + 1;
                    // Transição após o tempo de vedação
                    if (tempo_completo) begin
                        estado_atual <= CONCLUIDO;
                    end
                    // Se faltar rolha durante vedação, aborta
                    if (alarme_rolha) begin
                        estado_atual <= IDLE;
                    end
                end
                
                CONCLUIDO: begin
                    timer <= 0;
                    // Aguarda o comando ser desligado para voltar ao IDLE
                    if (!cmd_iniciar && cq_concluido) begin
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
    // Extração dos bits do estado (2 bits: estado_atual[1:0])
    // Codificação: IDLE=00, VEDANDO=01, CONCLUIDO=10
    wire state_bit0, state_bit1;
    buf (state_bit0, estado_atual[0]);
    buf (state_bit1, estado_atual[1]);
    
    // Sinais intermediários
    wire not_state_bit0, not_state_bit1;
    not (not_state_bit0, state_bit0);
    not (not_state_bit1, state_bit1);
    
    // vedacao_ativa = 1 quando estado_atual == VEDANDO (01)
    // Ou seja: state_bit1=0 AND state_bit0=1
    and (vedacao_ativa, not_state_bit1, state_bit0);
    
    // tarefa_concluida = 1 quando estado_atual == CONCLUIDO (10)
    // Ou seja: state_bit1=1 AND state_bit0=0
    and (tarefa_concluida, state_bit1, not_state_bit0);
    
    // decrementar_rolha = 1 quando estado_atual == VEDANDO (01) AND timer_igual_um
    // timer_igual_um é gerado sequencialmente, mas combinamos com o estado usando portas
    wire estado_vedando;
    and (estado_vedando, not_state_bit1, state_bit0);
    and (decrementar_rolha, estado_vedando, timer_igual_um);

endmodule

