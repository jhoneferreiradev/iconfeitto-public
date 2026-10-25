package br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.estoque.item;

import br.com.jhoneferreiradev.iconfeitto.api.grupovalidacao.ValidacaoInclusao;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;

@Schema(
        name = "Dados de custo do item",
        description = "Dados de custo do item")
public record DadosCustoDTOEntrada(
        @Schema(
                requiredMode = Schema.RequiredMode.NOT_REQUIRED,
                description = "Custo médio do item. Obrigatório na criação",
                example = "10.00")
        @NotNull(groups = ValidacaoInclusao.class)
        @Min(value = 0, groups = ValidacaoInclusao.class)
        BigDecimal custoMedio,

        @Schema(
                requiredMode = Schema.RequiredMode.NOT_REQUIRED,
                description = "Custo total de embalagem do item. Obrigatório na criação",
                example = "2.00")
        @NotNull(groups = ValidacaoInclusao.class)
        @Min(value = 0, groups = ValidacaoInclusao.class)
        BigDecimal custoEmbalagem,

        @Schema(
                requiredMode = Schema.RequiredMode.NOT_REQUIRED,
                description = "Custo operacional total do item. Obrigatório na criação",
                example = "1.50")
        @NotNull(groups = ValidacaoInclusao.class)
        @Min(value = 0, groups = ValidacaoInclusao.class)
        BigDecimal custoOperacional
) {
}
