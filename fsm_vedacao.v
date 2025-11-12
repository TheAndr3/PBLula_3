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
    output reg vedacao_ativa,            // LEDR[7] - Atuador de vedação
    output reg decrementar_rolha,        // Sinal para decrementar contador
    output reg tarefa_concluida          // Sinal de volta para o mestre
);

    // Estados da FSM
    localparam IDLE = 2'd0;
    localparam VEDANDO = 2'd1;
    localparam CONCLUIDO = 2'd2;
    
    reg [1:0] estado_atual;
    
    // Timer para simular o tempo de vedação (0.5 segundos)
    reg [25:0] timer;
    parameter TEMPO_VEDACAO = 26'd25000000; // 0.5s a 50MHz
    wire tempo_completo;
    
    assign tempo_completo = (timer >= TEMPO_VEDACAO);
    
    // Lógica de transição de estados (SEQUENCIAL)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            estado_atual <= IDLE;
            timer <= 0;
        end else begin
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
                    if (!cmd_iniciar) begin
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
            vedacao_ativa <= 1'b0;
            tarefa_concluida <= 1'b0;
            decrementar_rolha <= 1'b0;
        end else begin
            case (estado_atual)
                IDLE: begin
                    vedacao_ativa <= 1'b0;
                    tarefa_concluida <= 1'b0;
                    decrementar_rolha <= 1'b0;
                end
                
                VEDANDO: begin
                    vedacao_ativa <= 1'b1;  // Vedação ATIVA
                    tarefa_concluida <= 1'b0;
                    // Decrementa rolha no início da vedação (pulso único)
                    decrementar_rolha <= (timer == 1);
                end
                
                CONCLUIDO: begin
                    vedacao_ativa <= 1'b0;  // Vedação DESLIGADA
                    tarefa_concluida <= 1'b1;  // Sinaliza conclusão
                    decrementar_rolha <= 1'b0;
                end
                
                default: begin
                    vedacao_ativa <= 1'b0;
                    tarefa_concluida <= 1'b0;
                    decrementar_rolha <= 1'b0;
                end
            endcase
        end
    end

endmodule

