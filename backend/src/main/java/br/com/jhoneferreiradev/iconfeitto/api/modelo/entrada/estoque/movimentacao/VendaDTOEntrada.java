package br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.estoque.movimentacao;

import br.com.jhoneferreiradev.iconfeitto.api.grupovalidacao.ValidacaoInclusao;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.identificadores.ClienteIdDTO;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao.venda.StatusVenda;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao.venda.TipoVenda;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
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
public class VendaDTOEntrada extends AbstractMovimentacaoEstoqueDTOEntrada {

    @Schema(
            requiredMode = Schema.RequiredMode.NOT_REQUIRED,
            description = "Cliente da venda. Obrigatório na inclusão")
    @NotNull(groups = ValidacaoInclusao.class)
    @Valid
    private ClienteIdDTO cliente;

    @Schema(
            requiredMode = Schema.RequiredMode.NOT_REQUIRED,
            description = "Tipo da venda. Obrigatório na inclusão",
            examples = {"PRONTA_ENTREGA", "PROGRAMADA"})
    @NotNull(groups = ValidacaoInclusao.class)
    private TipoVenda tipoVenda;

    @Schema(
            requiredMode = Schema.RequiredMode.NOT_REQUIRED,
            description = "Status da venda. Obrigatório na inclusão",
            examples = {"PEDIDO", "EM_PRODUCAO", "AGUARDANDO_RETIRADA", "EM_ENTREGA", "ENTREGUE", "CANCELADA"})
    @NotNull(groups = ValidacaoInclusao.class)
    private StatusVenda statusVenda;

}
