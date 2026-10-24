package br.com.jhoneferreiradev.iconfeitto.api.modelo.saida.pessoa;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.PersonalidadeJuridica;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.EqualsAndHashCode;
import lombok.Getter;

@Schema(
        name = "CartaoDTOSaida",
        description = "Dados de um cartão")
@JsonIgnoreProperties(ignoreUnknown = true)
@EqualsAndHashCode(callSuper = true)
@Getter
public class CartaoDTOSaida extends AbstractPessoaDTOSaida {

    @Schema(
            requiredMode = Schema.RequiredMode.REQUIRED,
            description = "Dia do mês de vencimento da fatura do cartão",
            example = "10")
    private Integer diaVencimento;

    @Schema(
            requiredMode = Schema.RequiredMode.REQUIRED,
            description = "Quantidade de dias para o fechamento da fatura do cartão",
            example = "7")
    private Integer diasParaFechamento;

    public CartaoDTOSaida(Long id, String nome, PersonalidadeJuridica personalidadeJuridica,
                          Boolean ativo,
                          Integer diaVencimento, Integer diasParaFechamento) {
        super(id, nome, personalidadeJuridica, ativo);
        this.diaVencimento = diaVencimento;
        this.diasParaFechamento = diasParaFechamento;
    }
}
