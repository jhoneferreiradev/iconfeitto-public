package br.com.jhoneferreiradev.iconfeitto.api.documentacao.estoque;

import br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.estoque.item.ItemDTOEntrada;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.saida.estoque.item.ItemDTOSaida;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.parameters.RequestBody;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;

import java.util.List;

@Tag(name = "Item", description = "Gerenciamento dos itens")
public interface ItemControllerDoc {

    @Operation(
            summary = "Adiciona um novo item",
            description = "Adiciona um novo item ao sistema")
    ResponseEntity<ItemDTOSaida> adicionar(
            @RequestBody(
                    description = "Dados para a criação de um novo item",
                    useParameterTypeSchema = true) ItemDTOEntrada dto);

    @Operation(
            summary = "Lista os itens",
            description = "Retorna a lista de todos os itens cadastrados")
    ResponseEntity<List<ItemDTOSaida>> listar();

    @Operation(
            summary = "Busca um item por ID",
            description = "Retorna os detalhes de um item específico pelo seu ID")
    ResponseEntity<ItemDTOSaida> buscarPorId(
            @Parameter(
                    description = "ID único do item cadastrado",
                    example = "42",
                    required = true) Long id);

    @Operation(
            summary = "Atualiza um item",
            description = "Atualiza os detalhes de um item existente pelo seu ID. " +
                    "Atributos nulos ou não informados, serão ignorados e não sobrescreverão os valores existentes")
    ResponseEntity<ItemDTOSaida> atualizar(
            @Parameter(
                    description = "ID único do item cadastrado",
                    example = "42",
                    required = true) Long id,
            @RequestBody(
                    description = "Dados para atualização de um item. " +
                            "Atributos nulos ou não informados, serão ignorados e não sobrescreverão os valores existentes",
                    useParameterTypeSchema = true) ItemDTOEntrada dto);

}
