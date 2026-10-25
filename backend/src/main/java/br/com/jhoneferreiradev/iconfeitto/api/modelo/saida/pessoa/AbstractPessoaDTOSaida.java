package br.com.jhoneferreiradev.iconfeitto.api.modelo.saida.pessoa;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;

@JsonIgnoreProperties(ignoreUnknown = true)
@EqualsAndHashCode
@AllArgsConstructor
@Getter
@NoArgsConstructor
public abstract class AbstractPessoaDTOSaida {
    @Schema(
            requiredMode = Schema.RequiredMode.REQUIRED,
            description = "ID único do registro",
            example = "42")
    private Long id;

    @Schema(
            requiredMode = Schema.RequiredMode.REQUIRED,
            description = "Nome do registro")
    private String nome;

    @Schema(
            requiredMode = Schema.RequiredMode.NOT_REQUIRED,
            description = "Indica se o registro está ativo",
            example = "true")
    private Boolean ativo;
}
