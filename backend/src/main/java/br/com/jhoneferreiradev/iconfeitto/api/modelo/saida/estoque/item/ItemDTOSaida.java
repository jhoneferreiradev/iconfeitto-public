package br.com.jhoneferreiradev.iconfeitto.api.modelo.saida.estoque.item;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.item.TipoItem;
import io.swagger.v3.oas.annotations.media.Schema;

@Schema(
        name = "Item",
        description = "Dados de um item")
public record ItemDTOSaida(

        @Schema(
                description = "ID do item",
                example = "1")
        Long id,

        @Schema(
                description = "Nome do item",
                example = "Farinha de Trigo")
        String nome,

        @Schema(
                description = "Tipo do item",
                example = "INSUMO")
        TipoItem tipoItem,

        @Schema(description = "Dados de estoque do item")
        DadosEstoqueDTOSaida dadosEstoque,

        @Schema(description = "Dados da ficha técnica do item")
        DadosFichaTecnicaDTOSaida dadosFichaTecnica,

        @Schema(description = "Dados de custo do item")
        DadosCustoDTOSaida dadosCusto,

        @Schema(description = "Indica se o item está ativo")
        Boolean ativo
) {
}
