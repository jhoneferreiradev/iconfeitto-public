package br.com.jhoneferreiradev.iconfeitto.api.modelo.saida.estoque;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.unidademedida.GrupoUnidadeMedida;
import io.swagger.v3.oas.annotations.media.Schema;

import java.math.BigDecimal;

@Schema(
        name = "UnidadeMedidaDTOSaida",
        description = "Dados de uma unidade de medida")
public record UnidadeMedidaDTOSaida(
        @Schema(
                requiredMode = Schema.RequiredMode.REQUIRED,
                description = "ID único da unidade de medida",
                example = "42")
        Long id,

        @Schema(
                requiredMode = Schema.RequiredMode.REQUIRED,
                description = "Nome da unidade de medida",
                example = "Quilograma")
        String nome,

        @Schema(
                requiredMode = Schema.RequiredMode.REQUIRED,
                description = "Sigla da unidade de medida",
                example = "kg")
        String sigla,

        @Schema(
                requiredMode = Schema.RequiredMode.REQUIRED,
                description = "Grupo ao qual a unidade de medida pertence")
        GrupoUnidadeMedida grupo,

        @Schema(
                requiredMode = Schema.RequiredMode.REQUIRED,
                description = "Fator de conversão desta unidade para a unidade base do grupo",
                example = "1000")
        BigDecimal fatorParaBase,

        @Schema(
                requiredMode = Schema.RequiredMode.NOT_REQUIRED,
                description = "Indica se a unidade de medida está ativa",
                example = "true")
        Boolean ativo
) {
}
