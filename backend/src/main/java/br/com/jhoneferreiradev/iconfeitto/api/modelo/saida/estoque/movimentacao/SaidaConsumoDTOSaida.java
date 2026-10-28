package br.com.jhoneferreiradev.iconfeitto.api.modelo.saida.estoque.movimentacao;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.OffsetDateTime;
import java.util.List;

@Schema(
        name = "Saída para consumo",
        description = "Dados de uma saída para consumo")
@JsonIgnoreProperties(ignoreUnknown = true)
@EqualsAndHashCode(callSuper = true)
@Getter
@NoArgsConstructor
public class SaidaConsumoDTOSaida extends AbstractMovimentacaoEstoqueDTOSaida {

    public SaidaConsumoDTOSaida(Long id, OffsetDateTime data, List<ItemMovimentacaoEstoqueDTOSaida> itens) {
        super(id, data, itens);
    }
}
