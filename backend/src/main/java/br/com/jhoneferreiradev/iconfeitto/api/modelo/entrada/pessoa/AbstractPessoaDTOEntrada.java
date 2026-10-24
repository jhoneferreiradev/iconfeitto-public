package br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.pessoa;

import br.com.jhoneferreiradev.iconfeitto.api.grupovalidacao.ValidacaoInclusao;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.PersonalidadeJuridica;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.EqualsAndHashCode;
import lombok.Getter;

@JsonIgnoreProperties(ignoreUnknown = true)
@EqualsAndHashCode
@AllArgsConstructor
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
            description = "Personalidade jurídica",
            example = "PF")
    private PersonalidadeJuridica personalidadeJuridica;

    @Schema(
            requiredMode = Schema.RequiredMode.NOT_REQUIRED,
            description = "Indica se o registro está ativo",
            example = "true")
    private Boolean ativo;
}
