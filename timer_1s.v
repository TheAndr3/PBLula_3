module timer_1s (
    input wire clk,
    input wire reset,
    input wire start_trigger, // Sinal que inicia a contagem
    output sinal      // Variável que ficará em 1 por 1s
);

    // 1 segundo a 50MHz = 50.000.000 ciclos
    parameter CICLOS_1S = 26'd50000000;
    reg [25:0] contador;
    reg ativo; // Flag interna para indicar que a contagem está rodando
	 reg meu_sinal;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            meu_sinal <= 1'b0;
            contador <= 26'd0;
            ativo <= 1'b0;
        end else begin
            // Inicia a contagem ao receber o gatilho
            if (start_trigger && !ativo) begin
                ativo <= 1'b1;
                meu_sinal <= 1'b1; // Define a variável como 1
                contador <= 26'd0;
            end
            
            // Lógica de contagem
            if (ativo) begin
                if (contador < CICLOS_1S) begin
                    contador <= contador + 1;
                    meu_sinal <= 1'b1; // Mantém em 1
                end else begin
                    // Terminou o tempo
                    meu_sinal <= 1'b0; // Muda para 0
                    ativo <= 1'b0;     // Para a contagem
                    contador <= 26'd0;
                end
            end
        end
    end
	 
	 buf (sinal, meu_sinal);
endmodule