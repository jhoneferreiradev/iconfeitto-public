package br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.estoque.item;

import br.com.jhoneferreiradev.iconfeitto.api.grupovalidacao.ValidacaoInclusao;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.item.TipoItem;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

@Schema(
        name = "Item",
        description = "Dados para a criação ou atualização de um item. " +
                "Na atualização, atributos nulos ou não informados serão ignorados e não sobrescreverão os valores existentes")
public record ItemDTOEntrada(
        @Schema(
                requiredMode = Schema.RequiredMode.NOT_REQUIRED,
                description = "Nome do item. Obrigatório na criação",
                example = "Farinha de Trigo")
        @NotBlank(groups = ValidacaoInclusao.class)
        String nome,

        @Schema(
                requiredMode = Schema.RequiredMode.NOT_REQUIRED,
                description = "Tipo do item. Obrigatório na criação",
                example = "INSUMO")
        @NotNull(groups = ValidacaoInclusao.class)
        TipoItem tipoItem,

        @Schema(
                requiredMode = Schema.RequiredMode.NOT_REQUIRED,
                description = "Dados de estoque do item. Obrigatório na criação")
        @NotNull(groups = ValidacaoInclusao.class)
        @Valid
        DadosEstoqueDTOEntrada dadosEstoque,

        @Schema(
                requiredMode = Schema.RequiredMode.NOT_REQUIRED,
                description = "Dados da ficha técnica do item. Obrigatório na criação")
        @NotNull(groups = ValidacaoInclusao.class)
        @Valid
        DadosFichaTecnicaDTOEntrada dadosFichaTecnica,

        @Schema(
                requiredMode = Schema.RequiredMode.NOT_REQUIRED,
                description = "Dados de custo do item. Obrigatório na criação")
        @NotNull(groups = ValidacaoInclusao.class)
        @Valid
        DadosCustoDTOEntrada dadosCusto,

        @Schema(
                requiredMode = Schema.RequiredMode.NOT_REQUIRED,
                description = "Indica se o item está ativo")
        Boolean ativo
) {
}
