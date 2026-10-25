package br.com.jhoneferreiradev.iconfeitto.api.modelo.saida.estoque.item;

import br.com.jhoneferreiradev.iconfeitto.api.modelo.identificadores.UnidadeMedidaIdDTO;
import io.swagger.v3.oas.annotations.media.Schema;

import java.math.BigDecimal;

@Schema(
        name = "Dados de estoque do item",
        description = "Dados de estoque do item")
public record DadosEstoqueDTOSaida(

        @Schema(
                description = "ID da unidade de medida do estoque",
                example = "1")
        UnidadeMedidaIdDTO unidadeMedidaEstoque,

        @Schema(
                description = "ID da unidade de medida do consumo",
                example = "1")
        UnidadeMedidaIdDTO unidadeMedidaConsumo,

        @Schema(
                description = "Saldo do estoque",
                example = "100.00")
        BigDecimal saldoEstoque,

        @Schema(
                description = "Quantidade mínima do estoque",
                example = "10.00")
        BigDecimal quantidadeMinimaEstoque
) {
}
