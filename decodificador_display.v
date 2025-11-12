// ============================================================================
// Módulo: decodificador_display.v
// Descrição: Decodificador BCD para display de 7 segmentos
//            Converte valores de 0-99 em sinais para 2 displays
// Tipo: Verilog COMPORTAMENTAL
// ============================================================================

module decodificador_display (
    input wire [6:0] valor,        // Valor de 0 a 99
    output reg [6:0] hex1,         // Display dezena (ativo baixo)
    output reg [6:0] hex0          // Display unidade (ativo baixo)
);

    wire [3:0] dezena;
    wire [3:0] unidade;
    
    // Extração de dezena e unidade
    assign dezena = valor / 10;
    assign unidade = valor % 10;
    
    // Decodificação para HEX0 (unidade)
    always @(*) begin
        case (unidade)
            4'd0: hex0 = 7'b1000000; // 0
            4'd1: hex0 = 7'b1111001; // 1
            4'd2: hex0 = 7'b0100100; // 2
            4'd3: hex0 = 7'b0110000; // 3
            4'd4: hex0 = 7'b0011001; // 4
            4'd5: hex0 = 7'b0010010; // 5
            4'd6: hex0 = 7'b0000010; // 6
            4'd7: hex0 = 7'b1111000; // 7
            4'd8: hex0 = 7'b0000000; // 8
            4'd9: hex0 = 7'b0010000; // 9
            default: hex0 = 7'b1111111; // Apagado
        endcase
    end
    
    // Decodificação para HEX1 (dezena)
    always @(*) begin
        case (dezena)
            4'd0: hex1 = 7'b1000000; // 0
            4'd1: hex1 = 7'b1111001; // 1
            4'd2: hex1 = 7'b0100100; // 2
            4'd3: hex1 = 7'b0110000; // 3
            4'd4: hex1 = 7'b0011001; // 4
            4'd5: hex1 = 7'b0010010; // 5
            4'd6: hex1 = 7'b0000010; // 6
            4'd7: hex1 = 7'b1111000; // 7
            4'd8: hex1 = 7'b0000000; // 8
            4'd9: hex1 = 7'b0010000; // 9
            default: hex1 = 7'b1111111; // Apagado
        endcase
    end

endmodule
