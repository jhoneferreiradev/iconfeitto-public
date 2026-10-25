package br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.pessoa;

import br.com.jhoneferreiradev.iconfeitto.api.grupovalidacao.ValidacaoInclusao;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.bandeiracartao.TipoTaxaBandeiraCartao;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Schema(
        name = "Bandeira de cartão",
        description = "Dados para a criação ou atualização de uma bandeira de cartão. " +
                "Na atualização, atributos nulos ou não informados serão ignorados e não sobrescreverão os valores existentes",
        allOf = AbstractPessoaDTOEntrada.class)
@JsonIgnoreProperties(ignoreUnknown = true)
@EqualsAndHashCode(callSuper = true)
@Getter
@NoArgsConstructor
public class BandeiraCartaoDTOEntrada extends AbstractPessoaDTOEntrada {

    @Schema(
            requiredMode = Schema.RequiredMode.NOT_REQUIRED,
            description = "Taxa cobrada pela bandeira, interpretada conforme o tipo de taxa. Obrigatório na criação",
            example = "2.99")
    @NotNull(groups = ValidacaoInclusao.class)
    private BigDecimal taxa;

    @Schema(
            requiredMode = Schema.RequiredMode.NOT_REQUIRED,
            description = "Quantidade de dias para a compensação dos valores. Obrigatório na criação",
            example = "30")
    @NotNull(groups = ValidacaoInclusao.class)
    private Integer diasCompensacao;

    @Schema(
            requiredMode = Schema.RequiredMode.NOT_REQUIRED,
            description = "Tipo da taxa cobrada pela bandeira. Obrigatório na criação")
    @NotNull(groups = ValidacaoInclusao.class)
    private TipoTaxaBandeiraCartao tipoTaxa;

    public BandeiraCartaoDTOEntrada(String nome,
                                    Boolean ativo, BigDecimal taxa,
                                    Integer diasCompensacao, TipoTaxaBandeiraCartao tipoTaxa) {
        super(nome, ativo);
        this.taxa = taxa;
        this.diasCompensacao = diasCompensacao;
        this.tipoTaxa = tipoTaxa;
    }
}
