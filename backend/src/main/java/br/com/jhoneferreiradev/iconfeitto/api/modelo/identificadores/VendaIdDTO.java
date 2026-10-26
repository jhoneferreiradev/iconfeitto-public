package br.com.jhoneferreiradev.iconfeitto.api.modelo.identificadores;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;

@Schema(
        name = "Identificador venda",
        description = "Identificador de uma venda. Usado para referenciar uma venda em outras entidades")
public record VendaIdDTO(
        @Schema(
                requiredMode = Schema.RequiredMode.REQUIRED,
                description = "ID da venda",
                example = "1")
        @NotNull
        Long id
) {
}
