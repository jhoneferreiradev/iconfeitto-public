package br.com.jhoneferreiradev.iconfeitto.api.documentacao.pessoa;

import br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.pessoa.CartaoDTOEntrada;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.saida.pessoa.CartaoDTOSaida;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.parameters.RequestBody;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;

import java.util.List;

@Tag(name = "Cartão", description = "Gerenciamento dos cartões")
public interface CartaoControllerDoc {

    @Operation(
            summary = "Adiciona um novo cartão",
            description = "Adiciona um novo cartão ao sistema")
    ResponseEntity<CartaoDTOSaida> adicionar(
            @RequestBody(
                    description = "Dados para a criação de um novo cartão",
                    useParameterTypeSchema = true) CartaoDTOEntrada dtoNovaCartao);

    @Operation(
            summary = "Lista os cartões",
            description = "Retorna a lista de todos os cartões cadastrados")
    ResponseEntity<List<CartaoDTOSaida>> listar();

    @Operation(
            summary = "Busca um cartão por ID",
            description = "Retorna os detalhes de um cartão específico pelo seu ID")
    ResponseEntity<CartaoDTOSaida> buscarPorId(
            @Parameter(
                    description = "ID único do cartão cadastrado",
                    example = "42",
                    required = true) Long id);

    @Operation(
            summary = "Atualiza um cartão",
            description = "Atualiza os detalhes de um cartão existente pelo seu ID. " +
                    "Atributos nulos ou não informados, serão ignorados e não sobrescreverão os valores existentes")
    ResponseEntity<CartaoDTOSaida> atualizar(
            @Parameter(
                    description = "ID único do cartão cadastrado",
                    example = "42",
                    required = true) Long id,
            @RequestBody(
                    description = "Dados para atualização de um cartão. " +
                            "Atributos nulos ou não informados, serão ignorados e não sobrescreverão os valores existentes",
                    useParameterTypeSchema = true) CartaoDTOEntrada dtoAtualizacao);

}
