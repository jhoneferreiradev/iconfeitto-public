package br.com.jhoneferreiradev.iconfeitto.api.modelo.saida.estoque.movimentacao;

import br.com.jhoneferreiradev.iconfeitto.api.modelo.identificadores.ItemIdDTO;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.identificadores.UnidadeMedidaIdDTO;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;


@Schema(
        name = "Item Movimentação de Estoque",
        description = "Dados de um item de movimentação de estoque")
@JsonIgnoreProperties(ignoreUnknown = true)
@EqualsAndHashCode
@Getter
@NoArgsConstructor
public abstract class ItemMovimentacaoEstoqueDTOSaida {

    @Schema(description = "Identificador do item de movimentação de estoque")
    private Long id;

    @Schema(description = "Identificador do item")
    private ItemIdDTO item;

    @Schema(description = "Identificador da unidade de medida")
    private UnidadeMedidaIdDTO unidadeMedida;

    @Schema(description = "Quantidade do item")
    private BigDecimal quantidade;

    @Schema(description = "Valor unitário do item")
    private BigDecimal valorUnitario;

    public ItemMovimentacaoEstoqueDTOSaida(Long id,
                                           ItemIdDTO item,
                                           UnidadeMedidaIdDTO unidadeMedida,
                                           BigDecimal quantidade,
                                           BigDecimal valorUnitario) {
        this.id = id;
        this.item = item;
        this.unidadeMedida = unidadeMedida;
        this.quantidade = quantidade;
        this.valorUnitario = valorUnitario;
    }
}
