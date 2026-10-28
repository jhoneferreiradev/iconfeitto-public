package br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.estoque.movimentacao;

import br.com.jhoneferreiradev.iconfeitto.api.grupovalidacao.ValidacaoInclusao;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.identificadores.ItemIdDTO;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.identificadores.VendaIdDTO;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
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
public class FabricacaoDTOEntrada extends AbstractMovimentacaoEstoqueDTOEntrada {

    @Schema(
            requiredMode = Schema.RequiredMode.NOT_REQUIRED,
            description = "Item principal da fabricação. Obrigatório na inclusão")
    @NotNull(groups = ValidacaoInclusao.class)
    @Valid
    private ItemIdDTO itemPrincipal;

    @Schema(
            requiredMode = Schema.RequiredMode.NOT_REQUIRED,
            description = "Venda associada à fabricação")
    @Valid
    private VendaIdDTO venda;

    @Schema(
            requiredMode = Schema.RequiredMode.NOT_REQUIRED,
            description = "Quantidade produzida na fabricação. Obrigatório na inclusão"
    )
    @NotNull(groups = ValidacaoInclusao.class)
    @Min(value = 0, groups = ValidacaoInclusao.class)
    private BigDecimal quantidade;

}
