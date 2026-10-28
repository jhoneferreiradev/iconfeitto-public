package br.com.jhoneferreiradev.iconfeitto.api.modelo.saida.estoque.movimentacao;

import br.com.jhoneferreiradev.iconfeitto.api.modelo.identificadores.ItemIdDTO;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.identificadores.VendaIdDTO;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Schema(
        name = "Fabricação",
        description = "Dados de uma fabricação")
@JsonIgnoreProperties(ignoreUnknown = true)
@EqualsAndHashCode(callSuper = true)
@Getter
@NoArgsConstructor
@AllArgsConstructor
public class FabricacaoDTOSaida extends AbstractMovimentacaoEstoqueDTOSaida {

    @Schema(description = "Item principal da fabricação")
    private ItemIdDTO itemPrincipal;

    @Schema(description = "Venda associada à fabricação")
    private VendaIdDTO venda;

    @Schema(description = "Quantidade produzida na fabricação")
    private BigDecimal quantidade;

}
