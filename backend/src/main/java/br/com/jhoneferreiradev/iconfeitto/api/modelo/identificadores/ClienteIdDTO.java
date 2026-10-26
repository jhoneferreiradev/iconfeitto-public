package br.com.jhoneferreiradev.iconfeitto.api.modelo.identificadores;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;

@Schema(
        name = "Identificador cliente",
        description = "Identificador de um cliente. Usado para referenciar um cliente em outras entidades")
public record ClienteIdDTO(
        @Schema(
                requiredMode = Schema.RequiredMode.REQUIRED,
                description = "ID do cliente",
                example = "1")
        @NotNull
        Long id
) {
}
