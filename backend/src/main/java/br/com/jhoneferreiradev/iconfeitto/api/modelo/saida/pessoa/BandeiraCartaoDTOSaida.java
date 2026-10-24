package br.com.jhoneferreiradev.iconfeitto.api.modelo.saida.pessoa;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.PersonalidadeJuridica;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.bandeiracartao.TipoTaxaBandeiraCartao;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.EqualsAndHashCode;
import lombok.Getter;

import java.math.BigDecimal;

@Schema(
        name = "BandeiraCartaoDTOSaida",
        description = "Dados de uma bandeira de cartão")
@JsonIgnoreProperties(ignoreUnknown = true)
@EqualsAndHashCode(callSuper = true)
@Getter
public class BandeiraCartaoDTOSaida extends AbstractPessoaDTOSaida {

    @Schema(
            requiredMode = Schema.RequiredMode.REQUIRED,
            description = "Taxa cobrada pela bandeira, interpretada conforme o tipo de taxa",
            example = "2.99")
    private BigDecimal taxa;

    @Schema(
            requiredMode = Schema.RequiredMode.REQUIRED,
            description = "Quantidade de dias para a compensação dos valores",
            example = "30")
    private Integer diasCompensacao;

    @Schema(
            requiredMode = Schema.RequiredMode.REQUIRED,
            description = "Tipo da taxa cobrada pela bandeira")
    private TipoTaxaBandeiraCartao tipoTaxa;

    public BandeiraCartaoDTOSaida(Long id, String nome, PersonalidadeJuridica personalidadeJuridica,
                                  Boolean ativo, BigDecimal taxa,
                                  Integer diasCompensacao, TipoTaxaBandeiraCartao tipoTaxa) {
        super(id, nome, personalidadeJuridica, ativo);
        this.taxa = taxa;
        this.diasCompensacao = diasCompensacao;
        this.tipoTaxa = tipoTaxa;
    }
}
