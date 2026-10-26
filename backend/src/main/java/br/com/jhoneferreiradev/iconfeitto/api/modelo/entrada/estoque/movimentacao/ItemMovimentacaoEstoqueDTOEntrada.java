package br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.estoque.movimentacao;

import br.com.jhoneferreiradev.iconfeitto.api.grupovalidacao.ValidacaoInclusao;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.identificadores.ItemIdDTO;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.identificadores.UnidadeMedidaIdDTO;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;


@Schema(
        name = "Item Movimentação de Estoque",
        description = "Dados de um item de movimentação de estoque")
@JsonIgnoreProperties(ignoreUnknown = true)
@EqualsAndHashCode
@AllArgsConstructor
@Getter
@NoArgsConstructor
public abstract class ItemMovimentacaoEstoqueDTOEntrada {

    @Schema(
            requiredMode = Schema.RequiredMode.NOT_REQUIRED,
            description = "Identificador do item. Obrigatório na inclusão")
    @NotNull(groups = ValidacaoInclusao.class)
    private ItemIdDTO item;

    @Schema(
            requiredMode = Schema.RequiredMode.NOT_REQUIRED,
            description = "Identificador da unidade de medida. Obrigatório na inclusão")
    @NotNull(groups = ValidacaoInclusao.class)
    private UnidadeMedidaIdDTO unidadeMedida;

    @Schema(
            requiredMode = Schema.RequiredMode.NOT_REQUIRED,
            description = "Quantidade do item. Obrigatório na inclusão")
    @NotNull(groups = ValidacaoInclusao.class)
    @Min(value = 0, groups = ValidacaoInclusao.class)
    private BigDecimal quantidade;

    @Schema(
            requiredMode = Schema.RequiredMode.NOT_REQUIRED,
            description = "Valor unitário do item. Obrigatório na inclusão")
    @NotNull(groups = ValidacaoInclusao.class)
    @Min(value = 0, groups = ValidacaoInclusao.class)
    private BigDecimal valorUnitario;
}
