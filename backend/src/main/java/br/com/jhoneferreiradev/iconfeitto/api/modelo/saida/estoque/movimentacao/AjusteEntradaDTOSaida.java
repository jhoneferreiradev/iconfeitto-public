package br.com.jhoneferreiradev.iconfeitto.api.modelo.saida.estoque.movimentacao;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.OffsetDateTime;
import java.util.List;

@Schema(
        name = "Ajuste de entrada",
        description = "Dados de um ajuste de entrada")
@JsonIgnoreProperties(ignoreUnknown = true)
@EqualsAndHashCode(callSuper = true)
@Getter
@NoArgsConstructor
public class AjusteEntradaDTOSaida extends AbstractMovimentacaoEstoqueDTOSaida {

    public AjusteEntradaDTOSaida(Long id, OffsetDateTime data, List<ItemMovimentacaoEstoqueDTOSaida> itens) {
        super(id, data, itens);
    }
}
