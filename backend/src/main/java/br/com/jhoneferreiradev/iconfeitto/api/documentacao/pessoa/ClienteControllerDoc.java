package br.com.jhoneferreiradev.iconfeitto.api.documentacao.pessoa;

import br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.pessoa.ClienteDTOEntrada;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.saida.pessoa.ClienteDTOSaida;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.parameters.RequestBody;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;

import java.util.List;

@Tag(name = "Cliente", description = "Gerenciamento dos clientes")
public interface ClienteControllerDoc {

    @Operation(
            summary = "Adiciona um novo cliente",
            description = "Adiciona um novo cliente ao sistema")
    ResponseEntity<ClienteDTOSaida> adicionar(
            @RequestBody(
                    description = "Dados para a criação de um novo cliente",
                    useParameterTypeSchema = true) ClienteDTOEntrada dto);

    @Operation(
            summary = "Lista os clientes",
            description = "Retorna a lista de todos os clientes cadastrados")
    ResponseEntity<List<ClienteDTOSaida>> listar();

    @Operation(
            summary = "Busca um cliente por ID",
            description = "Retorna os detalhes de um cliente específico pelo seu ID")
    ResponseEntity<ClienteDTOSaida> buscarPorId(
            @Parameter(
                    description = "ID único do cliente cadastrado",
                    example = "42",
                    required = true) Long id);

    @Operation(
            summary = "Atualiza um cliente",
            description = "Atualiza os detalhes de um cliente existente pelo seu ID. " +
                    "Atributos nulos ou não informados, serão ignorados e não sobrescreverão os valores existentes")
    ResponseEntity<ClienteDTOSaida> atualizar(
            @Parameter(
                    description = "ID único do cliente cadastrado",
                    example = "42",
                    required = true) Long id,
            @RequestBody(
                    description = "Dados para atualização de um cliente. " +
                            "Atributos nulos ou não informados, serão ignorados e não sobrescreverão os valores existentes",
                    useParameterTypeSchema = true) ClienteDTOEntrada dto);

}
