package br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.estoque.movimentacao;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.OffsetDateTime;
import java.util.List;

@Schema(
        name = "Ajuste de saída",
        description = "Dados de um ajuste de saída")
@JsonIgnoreProperties(ignoreUnknown = true)
@EqualsAndHashCode(callSuper = true)
@Getter
@NoArgsConstructor
public class AjusteEntradaDTOSaida extends AbstractMovimentacaoEstoqueDTOEntrada {

    public AjusteEntradaDTOSaida(OffsetDateTime data, List<ItemMovimentacaoEstoqueDTOEntrada> itens) {
        super(data, itens);
    }
}
