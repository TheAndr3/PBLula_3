// ============================================================================
// Módulo: contador_duzias.v
// Descrição: Contador de dúzias (garrafas aprovadas)
//            Incrementa quando sensor final detecta garrafa
//            Reset automático ao atingir 10 dúzias
// Tipo: Verilog COMPORTAMENTAL
// ============================================================================

module contador_duzias (
    input wire clk,                      // Clock de 50MHz
    input wire reset,                    // Reset global
    input wire incrementar,              // Sinal para incrementar (sensor final)
    output reg [6:0] contador_valor      // Valor do contador (0-99)
);

    // Parâmetros
    parameter MAX_DUZIAS = 7'd10;        // Reset automático em 10 dúzias
    
    // Sincronização do sinal de entrada
    reg incrementar_prev;
    wire pulso_incrementar;
    
    // Detecta borda de subida do sinal
    assign pulso_incrementar = incrementar && !incrementar_prev;
    
    // Armazena sinal anterior
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            incrementar_prev <= 1'b0;
        end else begin
            incrementar_prev <= incrementar;
        end
    end
    
    // Lógica do contador
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            contador_valor <= 7'd0;
        end else begin
            // Reset automático ao atingir 10 dúzias
            if (contador_valor >= MAX_DUZIAS) begin
                contador_valor <= 7'd0;
            end
            // Incremento normal
            else if (pulso_incrementar) begin
                contador_valor <= contador_valor + 1;
            end
        end
    end

endmodule

