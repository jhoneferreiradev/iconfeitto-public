package br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.estoque.item;


import br.com.jhoneferreiradev.iconfeitto.api.modelo.identificadores.ItemIdDTO;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.identificadores.UnidadeMedidaIdDTO;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;

@Schema(
        name = "Item da ficha técnica do item",
        description = "Dados de um item da ficha técnica do item")
public record ItemFichaTecnicaDTOEntrada(

        @Schema(
                requiredMode = Schema.RequiredMode.REQUIRED,
                description = "Item da composição",
                example = "1")
        @NotNull
        ItemIdDTO itemComposicao,

        @Schema(
                requiredMode = Schema.RequiredMode.REQUIRED,
                description = "Unidade de medida do item da ficha técnica",
                example = "1")
        @NotNull
        UnidadeMedidaIdDTO unidadeMedida,

        @Schema(
                requiredMode = Schema.RequiredMode.REQUIRED,
                description = "Quantidade do item da ficha técnica",
                example = "1")
        @NotNull
        @Min(0)
        BigDecimal quantidade
) {
}
