// ============================================================================
// Módulo: debounce.v
// Descrição: Módulo debouncer para botões mecânicos
//            Gera um pulso de 1 ciclo de clock quando o botão é pressionado
// Tipo: Verilog COMPORTAMENTAL
// ============================================================================

module debounce (
    input wire clk,              // Clock de 50MHz
    input wire reset,            // Reset assíncrono
    input wire button_in,        // Entrada do botão (KEY)
    output reg pulse_out         // Pulso de saída (1 ciclo de clock)
);

    // Parâmetros para debounce
    // Para 50MHz, 20ms = 1.000.000 ciclos
    // Usaremos um contador de 20 bits (1.048.576 ciclos ~= 21ms)
    parameter COUNTER_WIDTH = 20;
    parameter COUNTER_MAX = 20'd1000000; // 20ms a 50MHz
    
    reg [COUNTER_WIDTH-1:0] counter;
    reg button_sync_0;          // Primeiro flip-flop de sincronização
    reg button_sync_1;          // Segundo flip-flop de sincronização
    reg button_stable;          // Estado estável do botão
    reg button_stable_prev;     // Estado estável anterior
    
    // Sincronização do sinal do botão (evita metaestabilidade)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            button_sync_0 <= 1'b1;  // KEY é ativo baixo (pull-up)
            button_sync_1 <= 1'b1;
        end else begin
            button_sync_0 <= button_in;
            button_sync_1 <= button_sync_0;
        end
    end
    
    // Lógica de debounce
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter <= 0;
            button_stable <= 1'b1;  // KEY é ativo baixo
        end else begin
            if (button_sync_1 != button_stable) begin
                // Botão mudou de estado, inicia contagem
                counter <= counter + 1;
                if (counter >= COUNTER_MAX) begin
                    // Tempo de debounce atingido, atualiza estado estável
                    button_stable <= button_sync_1;
                    counter <= 0;
                end
            end else begin
                // Botão não mudou, reseta contador
                counter <= 0;
            end
        end
    end
    
    // Armazena o estado anterior do botão
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            button_stable_prev <= 1'b1;
        end else begin
            button_stable_prev <= button_stable;
        end
    end
    
    // Geração do pulso de saída
    // KEY é ativo baixo: pulso ocorre na transição de 1 -> 0
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pulse_out <= 1'b0;
        end else begin
            // Detecta borda de descida (pressionar o botão)
            pulse_out <= (button_stable_prev == 1'b1) && (button_stable == 1'b0);
        end
    end

endmodule
