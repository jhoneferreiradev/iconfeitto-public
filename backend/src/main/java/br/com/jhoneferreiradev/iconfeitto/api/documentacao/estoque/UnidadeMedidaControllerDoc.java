package br.com.jhoneferreiradev.iconfeitto.api.documentacao.estoque;

import br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.estoque.unidademedida.UnidadeMedidaDTOEntrada;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.saida.estoque.UnidadeMedidaDTOSaida;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.parameters.RequestBody;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;

import java.util.List;

@Tag(name = "Unidade de Medida", description = "Gerenciamento das unidades de medida")
public interface UnidadeMedidaControllerDoc {

    @Operation(
            summary = "Adiciona uma nova unidade de medida",
            description = "Adiciona uma nova unidade de medida ao sistema")
    ResponseEntity<UnidadeMedidaDTOSaida> adicionar(
            @RequestBody(
                    description = "Dados para a criação de uma nova unidade de medida",
                    useParameterTypeSchema = true) UnidadeMedidaDTOEntrada dtoNovaUnidadeMedida);

    @Operation(
            summary = "Lista as unidades de medida",
            description = "Retorna a lista de todas as unidades de medida cadastradas")
    ResponseEntity<List<UnidadeMedidaDTOSaida>> listar();

    @Operation(
            summary = "Busca uma unidade de medida por ID",
            description = "Retorna os detalhes de uma unidade de medida específica pelo seu ID")
    ResponseEntity<UnidadeMedidaDTOSaida> buscarPorId(
            @Parameter(
                    description = "ID único da unidade de medida cadastrada",
                    example = "42",
                    required = true) Long id);

    @Operation(
            summary = "Atualiza uma unidade de medida",
            description = "Atualiza os detalhes de uma unidade de medida existente pelo seu ID. " +
                    "Atributos nulos ou não informados, serão ignorados e não sobrescreverão os valores existentes")
    ResponseEntity<UnidadeMedidaDTOSaida> atualizar(
            @Parameter(
                    description = "ID único da unidade de medida cadastrada",
                    example = "42",
                    required = true) Long id,
            @RequestBody(
                    description = "Dados para atualização de uma unidade de medida. " +
                            "Atributos nulos ou não informados, serão ignorados e não sobrescreverão os valores existentes",
                    useParameterTypeSchema = true) UnidadeMedidaDTOEntrada dtoAtualizacao);

}
