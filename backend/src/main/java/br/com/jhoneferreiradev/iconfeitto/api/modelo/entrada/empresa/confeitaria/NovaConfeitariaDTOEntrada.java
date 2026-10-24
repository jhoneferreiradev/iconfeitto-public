package br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.empresa.confeitaria;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;

@Schema(
        name = "NovaConfeitariaDTOEntrada",
        description = "Dados para a criação de uma nova confeitaria")
@JsonIgnoreProperties(ignoreUnknown = true)
public record NovaConfeitariaDTOEntrada(

        @Schema(
                requiredMode = Schema.RequiredMode.REQUIRED,
                description = "Nome da confeitaria",
                example = "Confeitaria Doce Sabor")
        @NotBlank
        String nome,

        @Schema(
                requiredMode = Schema.RequiredMode.REQUIRED,
                description = "Nome do usuário master",
                example = "João Silva")
        @NotBlank
        String nomeUsuarioMaster,

        @Schema(
                requiredMode = Schema.RequiredMode.REQUIRED,
                description = "Email do usuário master",
                example = "joao.silva@example.com")
        @NotBlank
        String emailUsuarioMaster
) {
}
