package br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.estoque.movimentacao;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao.venda.StatusVenda;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.OffsetDateTime;

@Schema(
        name = "Atualização de status da venda",
        description = "Novo status da venda")
@JsonIgnoreProperties(ignoreUnknown = true)
@EqualsAndHashCode(callSuper = true)
@Getter
@NoArgsConstructor
@AllArgsConstructor
public class AtualizacaoStatusVendaDTOEntrada extends AbstractMovimentacaoEstoqueDTOEntrada {

    @Schema(
            requiredMode = Schema.RequiredMode.REQUIRED,
            description = "Status da venda. Obrigatório",
            examples = {"PEDIDO", "EM_PRODUCAO", "AGUARDANDO_RETIRADA", "EM_ENTREGA", "ENTREGUE", "CANCELADA"})
    @NotNull
    private StatusVenda statusVenda;

    @Schema(
            requiredMode = Schema.RequiredMode.NOT_REQUIRED,
            description = "Data de entrega da venda. Obrigatório se o status for EM_ENTREGA ou ENTREGUE",
            examples = {"2024-06-01T10:00:00-03:00", "2024-06-02T15:30:00Z"})
    @NotNull
    private OffsetDateTime dataEntrega;

}
