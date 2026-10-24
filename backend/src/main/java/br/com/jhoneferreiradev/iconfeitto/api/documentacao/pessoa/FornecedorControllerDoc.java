package br.com.jhoneferreiradev.iconfeitto.api.documentacao.pessoa;

import br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.pessoa.FornecedorDTOEntrada;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.saida.pessoa.FornecedorDTOSaida;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.parameters.RequestBody;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;

import java.util.List;

@Tag(name = "Fornecedor", description = "Gerenciamento dos fornecedores")
public interface FornecedorControllerDoc {

    @Operation(
            summary = "Adiciona um novo fornecedor",
            description = "Adiciona um novo fornecedor ao sistema")
    ResponseEntity<FornecedorDTOSaida> adicionar(
            @RequestBody(
                    description = "Dados para a criação de um novo fornecedor",
                    useParameterTypeSchema = true) FornecedorDTOEntrada dtoNovaFornecedor);

    @Operation(
            summary = "Lista os fornecedores",
            description = "Retorna a lista de todos os fornecedores cadastrados")
    ResponseEntity<List<FornecedorDTOSaida>> listar();

    @Operation(
            summary = "Busca um fornecedor por ID",
            description = "Retorna os detalhes de um fornecedor específico pelo seu ID")
    ResponseEntity<FornecedorDTOSaida> buscarPorId(
            @Parameter(
                    description = "ID único do fornecedor cadastrado",
                    example = "42",
                    required = true) Long id);

    @Operation(
            summary = "Atualiza um fornecedor",
            description = "Atualiza os detalhes de um fornecedor existente pelo seu ID. " +
                    "Atributos nulos ou não informados, serão ignorados e não sobrescreverão os valores existentes")
    ResponseEntity<FornecedorDTOSaida> atualizar(
            @Parameter(
                    description = "ID único do fornecedor cadastrado",
                    example = "42",
                    required = true) Long id,
            @RequestBody(
                    description = "Dados para atualização de um fornecedor. " +
                            "Atributos nulos ou não informados, serão ignorados e não sobrescreverão os valores existentes",
                    useParameterTypeSchema = true) FornecedorDTOEntrada dtoAtualizacao);

}
