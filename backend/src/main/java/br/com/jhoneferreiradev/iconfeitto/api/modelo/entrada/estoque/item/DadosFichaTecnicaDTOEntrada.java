package br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.estoque.item;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.Valid;

import java.util.List;

@Schema(
        name = "Ficha técnica do item",
        description = "Dados da ficha técnica do item. Obrigatório na criação")
public record DadosFichaTecnicaDTOEntrada(
        @Schema(
                requiredMode = Schema.RequiredMode.NOT_REQUIRED,
                description = "Indica se o item possui ficha técnica",
                example = "true")
        Boolean possuiFichaTecnica,

        @Schema(
                requiredMode = Schema.RequiredMode.NOT_REQUIRED,
                description = "Tempo de preparo da receita em minutos",
                example = "30")
        Integer tempoPreparoMinutos,
        @Schema(
                requiredMode = Schema.RequiredMode.NOT_REQUIRED,
                description = "Rendimento da receita",
                example = "4")
        Integer rendimentoReceita,

        @Schema(
                requiredMode = Schema.RequiredMode.NOT_REQUIRED,
                description = "Itens da ficha técnica",
                example = "[{\"idItemComposicao\": 1, \"idUnidadeMedida\": 1, \"quantidade\": 1}]")
        @Valid
        List<ItemFichaTecnicaDTOEntrada> itens
) {
}
