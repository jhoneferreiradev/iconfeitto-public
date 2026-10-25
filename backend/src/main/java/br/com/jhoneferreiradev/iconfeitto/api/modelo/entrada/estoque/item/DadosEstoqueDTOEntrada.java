package br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.estoque.item;

import br.com.jhoneferreiradev.iconfeitto.api.grupovalidacao.ValidacaoInclusao;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.identificadores.UnidadeMedidaIdDTO;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;

@Schema(
        name = "Dados de estoque do item",
        description = "Dados de estoque do item")
public record DadosEstoqueDTOEntrada(

        @Schema(
                requiredMode = Schema.RequiredMode.NOT_REQUIRED,
                description = "ID da unidade de medida do estoque. Obrigatório na criação",
                example = "1")
        @NotNull(groups = ValidacaoInclusao.class)
        @Valid
        UnidadeMedidaIdDTO unidadeMedidaEstoque,

        @Schema(
                requiredMode = Schema.RequiredMode.NOT_REQUIRED,
                description = "ID da unidade de medida do consumo. Obrigatório na criação",
                example = "1")
        @NotNull(groups = ValidacaoInclusao.class)
        @Valid
        UnidadeMedidaIdDTO unidadeMedidaConsumo,

        @Schema(
                requiredMode = Schema.RequiredMode.NOT_REQUIRED,
                description = "Saldo do estoque. Obrigatório na criação",
                example = "100.00")
        @NotNull(groups = ValidacaoInclusao.class)
        @Min(value = 0, groups = ValidacaoInclusao.class)
        BigDecimal saldoEstoque,

        @Schema(
                requiredMode = Schema.RequiredMode.NOT_REQUIRED,
                description = "Quantidade mínima do estoque. Obrigatório na criação",
                example = "10.00")
        @NotNull(groups = ValidacaoInclusao.class)
        @Min(value = 0, groups = ValidacaoInclusao.class)
        BigDecimal quantidadeMinimaEstoque
) {
}
