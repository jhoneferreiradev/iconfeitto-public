package br.com.jhoneferreiradev.iconfeitto.api.documentacao.empresa;

import br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.empresa.custooperacional.CustoOperacionalDTOEntrada;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.saida.empresa.custooperacional.CustoOperacionalDTOSaida;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.parameters.RequestBody;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;

import java.util.List;

@Tag(name = "Custo Operacional", description = "Gerenciamento dos custos operacionais")
public interface CustoOperacionalControllerDoc {

    @Operation(
            summary = "Adiciona um novo custo operacional",
            description = "Adiciona um novo custo operacional ao sistema")
    ResponseEntity<CustoOperacionalDTOSaida> adicionar(
            @RequestBody(
                    description = "Dados para a criação de um novo custo operacional",
                    useParameterTypeSchema = true) CustoOperacionalDTOEntrada dto);

    @Operation(
            summary = "Lista os custos operacionais",
            description = "Retorna a lista de todos os custos operacionais cadastrados")
    ResponseEntity<List<CustoOperacionalDTOSaida>> listar();

    @Operation(
            summary = "Busca um custo operacional por ID",
            description = "Retorna os detalhes de um custo operacional específico pelo seu ID")
    ResponseEntity<CustoOperacionalDTOSaida> buscarPorId(
            @Parameter(
                    description = "ID único do custo operacional cadastrado",
                    example = "42",
                    required = true) Long id);

    @Operation(
            summary = "Atualiza um custo operacional",
            description = "Atualiza os detalhes de um custo operacional existente pelo seu ID. " +
                    "Atributos nulos ou não informados, serão ignorados e não sobrescreverão os valores existentes")
    ResponseEntity<CustoOperacionalDTOSaida> atualizar(
            @Parameter(
                    description = "ID único do custo operacional cadastrado",
                    example = "42",
                    required = true) Long id,
            @RequestBody(
                    description = "Dados para atualização de um custo operacional. " +
                            "Atributos nulos ou não informados, serão ignorados e não sobrescreverão os valores existentes",
                    useParameterTypeSchema = true) CustoOperacionalDTOEntrada dto);

    @Operation(
            summary = "Remove um custo operacional",
            description = "Remove um custo operacional existente pelo seu ID")
    ResponseEntity<Void> remover(
            @Parameter(
                    description = "ID único do custo operacional cadastrado",
                    example = "42",
                    required = true) Long id);

}
