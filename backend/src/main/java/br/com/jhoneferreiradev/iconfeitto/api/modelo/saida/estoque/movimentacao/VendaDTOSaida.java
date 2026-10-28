package br.com.jhoneferreiradev.iconfeitto.api.modelo.saida.estoque.movimentacao;

import br.com.jhoneferreiradev.iconfeitto.api.modelo.identificadores.ClienteIdDTO;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Schema(
        name = "Venda",
        description = "Dados de uma venda")
@JsonIgnoreProperties(ignoreUnknown = true)
@EqualsAndHashCode(callSuper = true)
@Getter
@NoArgsConstructor
@AllArgsConstructor
public class VendaDTOSaida extends AbstractMovimentacaoEstoqueDTOSaida {

    @Schema(description = "Cliente da venda. Obrigatório na inclusão")
    private ClienteIdDTO cliente;

}
