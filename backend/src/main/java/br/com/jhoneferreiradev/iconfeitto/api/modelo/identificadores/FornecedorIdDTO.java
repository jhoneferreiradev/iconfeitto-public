package br.com.jhoneferreiradev.iconfeitto.api.modelo.identificadores;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;

@Schema(
        name = "Identificador fornecedor",
        description = "Identificador de um fornecedor. Usado para referenciar um fornecedor em outras entidades")
public record FornecedorIdDTO(
        @Schema(
                requiredMode = Schema.RequiredMode.REQUIRED,
                description = "ID do fornecedor",
                example = "1")
        @NotNull
        Long id
) {
}
