package br.com.jhoneferreiradev.iconfeitto.api.modelo.saida.pessoa;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.PersonalidadeJuridica;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.TipoPessoa;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.EqualsAndHashCode;
import lombok.Getter;

@JsonIgnoreProperties(ignoreUnknown = true)
@EqualsAndHashCode
@AllArgsConstructor
@Getter
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
            description = "Personalidade jurídica",
            example = "PF")
    private PersonalidadeJuridica personalidadeJuridica;

    @Schema(
            requiredMode = Schema.RequiredMode.NOT_REQUIRED,
            description = "Indica se o registro está ativo",
            example = "true")
    private Boolean ativo;
}
