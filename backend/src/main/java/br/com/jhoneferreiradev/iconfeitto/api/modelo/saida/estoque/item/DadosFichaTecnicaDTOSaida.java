package br.com.jhoneferreiradev.iconfeitto.api.modelo.saida.estoque.item;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;

import java.util.List;

@Schema(
        name = "Ficha da ficha técnica do item",
        description = "Dados da ficha técnica do item")
public record DadosFichaTecnicaDTOSaida(
        @Schema(
                description = "Indica se o item possui ficha técnica",
                example = "true")
        Boolean possuiFichaTecnica,

        @Schema(
                requiredMode = Schema.RequiredMode.REQUIRED,
                description = "Tempo de preparo da receita em minutos",
                example = "30")
        Integer tempoPreparoMinutos,
        @Schema(
                description = "Rendimento da receita",
                example = "4")
        Integer rendimentoReceita,

        @Schema(
                description = "Itens da ficha técnica",
                example = "[{\"idItemComposicao\": 1, \"idUnidadeMedida\": 1, \"quantidade\": 1}]")
        List<ItemFichaTecnicaDTOSaida> itens
) {
}
