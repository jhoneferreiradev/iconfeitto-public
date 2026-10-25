package br.com.jhoneferreiradev.iconfeitto.api.modelo.saida.pessoa;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Schema(
        name = "Cartão",
        description = "Dados de um cartão")
@JsonIgnoreProperties(ignoreUnknown = true)
@EqualsAndHashCode(callSuper = true)
@Getter
@NoArgsConstructor
public class CartaoDTOSaida extends AbstractPessoaDTOSaida {

    @Schema(
            description = "Dia do mês de vencimento da fatura do cartão",
            example = "10")
    private Integer diaVencimento;

    @Schema(
            description = "Quantidade de dias para o fechamento da fatura do cartão",
            example = "7")
    private Integer diasParaFechamento;

    public CartaoDTOSaida(Long id, String nome,
                          Boolean ativo,
                          Integer diaVencimento, Integer diasParaFechamento) {
        super(id, nome, ativo);
        this.diaVencimento = diaVencimento;
        this.diasParaFechamento = diasParaFechamento;
    }
}
