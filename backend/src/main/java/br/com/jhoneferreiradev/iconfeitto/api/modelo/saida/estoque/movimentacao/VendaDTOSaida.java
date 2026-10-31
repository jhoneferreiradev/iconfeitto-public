package br.com.jhoneferreiradev.iconfeitto.api.modelo.saida.estoque.movimentacao;

import br.com.jhoneferreiradev.iconfeitto.api.modelo.identificadores.ClienteIdDTO;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao.venda.StatusVenda;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao.venda.TipoVenda;
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

    @Schema(description = "Cliente da venda")
    private ClienteIdDTO cliente;

    @Schema(
            requiredMode = Schema.RequiredMode.NOT_REQUIRED,
            description = "Tipo da venda",
            examples = {"PRONTA_ENTREGA", "PROGRAMADA"})
    private TipoVenda tipoVenda;

    @Schema(
            requiredMode = Schema.RequiredMode.NOT_REQUIRED,
            description = "Status da venda",
            examples = {"PEDIDO", "EM_PRODUCAO", "AGUARDANDO_RETIRADA", "EM_ENTREGA", "ENTREGUE", "CANCELADA"})
    private StatusVenda statusVenda;

}
