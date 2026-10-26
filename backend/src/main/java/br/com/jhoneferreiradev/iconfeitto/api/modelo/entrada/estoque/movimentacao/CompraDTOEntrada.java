package br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.estoque.movimentacao;

import br.com.jhoneferreiradev.iconfeitto.api.grupovalidacao.ValidacaoInclusao;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.identificadores.FornecedorIdDTO;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Schema(
        name = "Compra",
        description = "Dados de uma compra")
@JsonIgnoreProperties(ignoreUnknown = true)
@EqualsAndHashCode(callSuper = true)
@Getter
@NoArgsConstructor
@AllArgsConstructor
public class CompraDTOEntrada extends AbstractMovimentacaoEstoqueDTOEntrada {

    @Schema(
            requiredMode = Schema.RequiredMode.NOT_REQUIRED,
            description = "Fornecedor da compra. Obrigatório na inclusão")
    @NotNull(groups = ValidacaoInclusao.class)
    @Valid
    private FornecedorIdDTO fornecedor;

}
