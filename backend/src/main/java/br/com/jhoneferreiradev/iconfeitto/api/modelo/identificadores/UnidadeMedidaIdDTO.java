package br.com.jhoneferreiradev.iconfeitto.api.modelo.identificadores;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;

@Schema(
        name = "Identificador Unidade de medida",
        description = "Identificador de uma unidade de medida. Usado para referenciar uma unidade de medida em outras entidades")
public record UnidadeMedidaIdDTO(
        @Schema(
                requiredMode = Schema.RequiredMode.REQUIRED,
                description = "ID da unidade de medida",
                example = "1")
        @NotNull
        Long id
) {
}
