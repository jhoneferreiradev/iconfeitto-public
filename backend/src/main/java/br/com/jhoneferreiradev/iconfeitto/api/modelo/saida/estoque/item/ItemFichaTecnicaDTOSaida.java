package br.com.jhoneferreiradev.iconfeitto.api.modelo.saida.estoque.item;


import br.com.jhoneferreiradev.iconfeitto.api.modelo.identificadores.ItemIdDTO;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.identificadores.UnidadeMedidaIdDTO;
import io.swagger.v3.oas.annotations.media.Schema;

import java.math.BigDecimal;

@Schema(
        name = "Item da ficha técnica do item",
        description = "Dados de um item da ficha técnica do item")
public record ItemFichaTecnicaDTOSaida(

        @Schema(
                description = "ID do item da composição",
                example = "1")
        ItemIdDTO itemComposicao,

        @Schema(
                description = "ID da unidade de medida do item da ficha técnica",
                example = "1")
        UnidadeMedidaIdDTO unidadeMedida,

        @Schema(
                description = "Quantidade do item da ficha técnica",
                example = "1")
        BigDecimal quantidade
) {
}
