package br.com.jhoneferreiradev.iconfeitto.api.modelo.saida.estoque.item;

import io.swagger.v3.oas.annotations.media.Schema;

import java.math.BigDecimal;

@Schema(
        name = "Dados de custo do item",
        description = "Dados de custo do item")
public record DadosCustoDTOSaida(
        @Schema(
                description = "Custo médio do item",
                example = "10.00")
        BigDecimal custoMedio,

        @Schema(
                description = "Custo total de embalagem do item",
                example = "2.00")
        BigDecimal custoEmbalagem,

        @Schema(
                description = "Custo operacional total do item",
                example = "1.50")
        BigDecimal custoOperacional
) {
}
