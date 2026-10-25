package br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.pessoa;

import br.com.jhoneferreiradev.iconfeitto.api.grupovalidacao.ValidacaoInclusao;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;

@JsonIgnoreProperties(ignoreUnknown = true)
@EqualsAndHashCode
@AllArgsConstructor
@NoArgsConstructor
@Getter
@Schema(hidden = true)
public abstract class AbstractPessoaDTOEntrada {
    @Schema(
            requiredMode = Schema.RequiredMode.NOT_REQUIRED,
            description = "Nome do registro. Obrigatório na criação")
    @NotBlank(groups = ValidacaoInclusao.class)
    private String nome;

    @Schema(
            requiredMode = Schema.RequiredMode.NOT_REQUIRED,
            description = "Indica se o registro está ativo",
            example = "true")
    private Boolean ativo;
}
