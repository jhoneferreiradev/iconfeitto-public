package br.com.jhoneferreiradev.iconfeitto.api.modelo.saida.estoque.movimentacao;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import io.swagger.v3.oas.annotations.media.Schema;
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
public abstract class AbstractMovimentacaoEstoqueDTOSaida {

    @Schema(description = "Identificador da movimentação de estoque")
    private Long id;

    @Schema(description = "Data da movimentação de estoque")
    private OffsetDateTime data;

    @Schema(description = "Tipo da movimentação de estoque")
    private List<ItemMovimentacaoEstoqueDTOSaida> itens;
}
