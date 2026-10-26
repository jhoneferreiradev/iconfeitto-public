package br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.estoque.movimentacao;

import br.com.jhoneferreiradev.iconfeitto.api.grupovalidacao.ValidacaoInclusao;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.OffsetDateTime;
import java.util.List;

@Schema(hidden = true)
@JsonIgnoreProperties(ignoreUnknown = true)
@EqualsAndHashCode
@AllArgsConstructor
@Getter
@NoArgsConstructor
public abstract class AbstractMovimentacaoEstoqueDTOEntrada {
    @Schema(
            requiredMode = Schema.RequiredMode.NOT_REQUIRED,
            description = "Data da movimentação de estoque. Obrigatório na inclusão")
    @NotNull(groups = ValidacaoInclusao.class)
    private OffsetDateTime data;

    @Schema(
            requiredMode = Schema.RequiredMode.NOT_REQUIRED,
            description = "Tipo da movimentação de estoque. Obrigatório na inclusão")
    @NotNull(groups = ValidacaoInclusao.class)
    @Valid
    private List<ItemMovimentacaoEstoqueDTOEntrada> itens;
}
