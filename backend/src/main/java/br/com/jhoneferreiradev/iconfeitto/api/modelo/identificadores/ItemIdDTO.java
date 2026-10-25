package br.com.jhoneferreiradev.iconfeitto.api.modelo.identificadores;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;

@Schema(
        name = "Identificador Item",
        description = "Identificador de um item. Usado para referenciar um item em outras entidades")
public record ItemIdDTO(
        @Schema(
                requiredMode = Schema.RequiredMode.REQUIRED,
                description = "ID do item",
                example = "1")
        @NotNull
        Long id
) {
}
