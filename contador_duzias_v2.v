module contador_duzias_v2 (
    input wire clk,
    input wire reset,
    input wire incrementar,
    output reg [6:0] contador_valor
);

    parameter MAX_DUZIAS = 7'd10;
    parameter DUZIA = 7'd12;
    
    reg [3:0] doze;
    reg incrementar_prev;       // Registrador para armazenar o estado anterior
    wire pulso_subida;          // Fio para o pulso único

    // 1. Detector de Borda de Subida
    // O pulso só é 1 quando agora é 1 e antes era 0
    assign pulso_subida = incrementar && !incrementar_prev;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            contador_valor <= 7'd0;
            doze <= 4'd0;
            incrementar_prev <= 1'b0;
        end else begin
            // Atualiza o histórico do botão a cada clock
            incrementar_prev <= incrementar;

            // 2. Só incrementa se houver o pulso (borda)
            if (pulso_subida) begin
                if (doze >= DUZIA - 1) begin // -1 pois o incremento ocorre neste ciclo
                    doze <= 0;
                    if (contador_valor >= MAX_DUZIAS)
                        contador_valor <= 0; // Reset global das dúzias
                    else
                        contador_valor <= contador_valor + 1;
                end else begin
                    doze <= doze + 1;
                end
            end
        end
    end

endmodule