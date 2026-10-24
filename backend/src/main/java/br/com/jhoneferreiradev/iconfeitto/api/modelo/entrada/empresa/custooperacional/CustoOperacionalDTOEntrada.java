package br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.empresa.custooperacional;

import br.com.jhoneferreiradev.iconfeitto.api.grupovalidacao.ValidacaoInclusao;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;

@Schema(
        name = "CustoOperacionalDTOEntrada",
        description = "Dados para a criação ou atualização de um custo operacional. " +
                "Na atualização, atributos nulos ou não informados serão ignorados e não sobrescreverão os valores existentes")
public record CustoOperacionalDTOEntrada(
        @Schema(
                requiredMode = Schema.RequiredMode.NOT_REQUIRED,
                description = "Nome do custo operacional. Obrigatório na criação",
                example = "Energia elétrica")
        @NotBlank(groups = ValidacaoInclusao.class)
        String nome,

        @Schema(
                requiredMode = Schema.RequiredMode.NOT_REQUIRED,
                description = "Valor do custo operacional. Obrigatório na criação",
                example = "350.00")
        @NotNull(groups = ValidacaoInclusao.class)
        BigDecimal valor
) {
}
