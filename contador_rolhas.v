// ============================================================================
// Módulo: contador_rolhas.v
// Descrição: Contador de rolhas com lógica de decremento, reposição automática,
//            reposição manual, alarme e controle do dispensador
// Tipo: Verilog COMPORTAMENTAL
// ============================================================================

module contador_rolhas (
    input wire clk,                      // Clock de 50MHz
    input wire reset,                    // Reset global
    input wire decrementar,              // Sinal para decrementar (vedação concluída)
    input wire sw_adicionar_manual,      // SW7 - Adicionar 1 rolha manualmente
    output reg dispensador_ativo,        // LEDR[5] - Dispensador
    output reg alarme_rolha_vazia,       // LEDR[0] - Alarme falta de rolha
    output reg [6:0] contador_valor      // Valor do contador (0-99)
);

    // Parâmetros
    parameter MAX_ROLHAS = 7'd99;
    parameter LIMITE_REPOSICAO = 7'd5;   // Repõe quando atingir 5
    parameter QTD_REPOSICAO = 7'd15;     // Adiciona 15 rolhas
    
    // Estados da lógica de reposição automática
    localparam IDLE = 2'd0;
    localparam DISPENSANDO = 2'd1;
    localparam AGUARDANDO = 2'd2;
    
    reg [1:0] estado_dispensador;
    reg [25:0] timer_dispensador;        // Timer para simulação do dispensador
    parameter TEMPO_DISPENSADOR = 26'd50000000; // 1 segundo a 50MHz
    
    // Sincronização dos sinais de entrada
    reg decrementar_prev;
    reg sw_adicionar_prev;
    wire pulso_decrementar;
    wire pulso_adicionar;
    
    // Detecta borda de subida dos sinais
    assign pulso_decrementar = decrementar && !decrementar_prev;
    assign pulso_adicionar = sw_adicionar_manual && !sw_adicionar_prev;
    
    // Armazena sinais anteriores
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            decrementar_prev <= 1'b0;
            sw_adicionar_prev <= 1'b0;
        end else begin
            decrementar_prev <= decrementar;
            sw_adicionar_prev <= sw_adicionar_manual;
        end
    end
    
    // Lógica principal do contador
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            contador_valor <= 7'd20;  // Valor inicial: 20 rolhas
            alarme_rolha_vazia <= 1'b0;
        end else begin
            // Prioridade: Reposição automática > Reposição manual > Decremento
            if (estado_dispensador == DISPENSANDO) begin
                // Durante a reposição automática, não aceita outras operações
                // O dispensador adiciona 15 rolhas de uma vez ao final
            end else if (pulso_adicionar && contador_valor < MAX_ROLHAS) begin
                // Adição manual (SW7)
                contador_valor <= contador_valor + 1;
                alarme_rolha_vazia <= 1'b0;
            end else if (pulso_decrementar && contador_valor > 0) begin
                // Decremento (vedação)
                contador_valor <= contador_valor - 1;
                if (contador_valor == 1) begin
                    // Vai ficar em 0 após o decremento
                    alarme_rolha_vazia <= 1'b1;
                end
            end
            
            // Atualiza alarme se contador já está em 0
            if (contador_valor == 0) begin
                alarme_rolha_vazia <= 1'b1;
            end else begin
                alarme_rolha_vazia <= 1'b0;
            end
        end
    end
    
    // Máquina de estados para o dispensador automático
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            estado_dispensador <= IDLE;
            dispensador_ativo <= 1'b0;
            timer_dispensador <= 0;
        end else begin
            case (estado_dispensador)
                IDLE: begin
                    dispensador_ativo <= 1'b0;
                    timer_dispensador <= 0;
                    
                    // Verifica se precisa repor (quando chegar a 5)
                    if (contador_valor == LIMITE_REPOSICAO) begin
                        estado_dispensador <= DISPENSANDO;
                        dispensador_ativo <= 1'b1;
                    end
                end
                
                DISPENSANDO: begin
                    dispensador_ativo <= 1'b1;
                    timer_dispensador <= timer_dispensador + 1;
                    
                    // Simula o tempo de dispensação (1 segundo)
                    if (timer_dispensador >= TEMPO_DISPENSADOR) begin
                        // Adiciona as rolhas
                        if (contador_valor + QTD_REPOSICAO <= MAX_ROLHAS) begin
                            contador_valor <= contador_valor + QTD_REPOSICAO;
                        end else begin
                            contador_valor <= MAX_ROLHAS;
                        end
                        
                        estado_dispensador <= AGUARDANDO;
                        dispensador_ativo <= 1'b0;
                        timer_dispensador <= 0;
                    end
                end
                
                AGUARDANDO: begin
                    dispensador_ativo <= 1'b0;
                    
                    // Aguarda o contador sair do limite de reposição
                    // (evita reposições múltiplas consecutivas)
                    if (contador_valor != LIMITE_REPOSICAO && 
                        contador_valor != (LIMITE_REPOSICAO + QTD_REPOSICAO)) begin
                        estado_dispensador <= IDLE;
                    end
                end
                
                default: begin
                    estado_dispensador <= IDLE;
                    dispensador_ativo <= 1'b0;
                end
            endcase
        end
    end

endmodule

