package br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.pessoa;

import br.com.jhoneferreiradev.iconfeitto.api.grupovalidacao.ValidacaoInclusao;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.PersonalidadeJuridica;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.EqualsAndHashCode;
import lombok.Getter;

@Schema(
        name = "Cartão",
        description = "Dados para a criação ou atualização de um cartão. " +
                "Na atualização, atributos nulos ou não informados serão ignorados e não sobrescreverão os valores existentes",
        allOf = AbstractPessoaDTOEntrada.class)
@JsonIgnoreProperties(ignoreUnknown = true)
@EqualsAndHashCode(callSuper = true)
@Getter
public class CartaoDTOEntrada extends AbstractPessoaDTOEntrada {

    @Schema(
            requiredMode = Schema.RequiredMode.NOT_REQUIRED,
            description = "Dia do mês de vencimento da fatura do cartão. Obrigatório na criação",
            example = "10")
    @NotNull(groups = ValidacaoInclusao.class)
    @Min(value = 1, groups = ValidacaoInclusao.class)
    @Max(value = 31, groups = ValidacaoInclusao.class)
    private Integer diaVencimento;

    @Schema(
            requiredMode = Schema.RequiredMode.NOT_REQUIRED,
            description = "Quantidade de dias para o fechamento da fatura do cartão. Obrigatório na criação",
            example = "7")
    @NotNull(groups = ValidacaoInclusao.class)
    @Min(value = 1, groups = ValidacaoInclusao.class)
    private Integer diasParaFechamento;

    public CartaoDTOEntrada(String nome, PersonalidadeJuridica personalidadeJuridica,
                            Boolean ativo,
                            Integer diaVencimento, Integer diasParaFechamento) {
        super(nome, personalidadeJuridica, ativo);
        this.diaVencimento = diaVencimento;
        this.diasParaFechamento = diasParaFechamento;
    }
}
