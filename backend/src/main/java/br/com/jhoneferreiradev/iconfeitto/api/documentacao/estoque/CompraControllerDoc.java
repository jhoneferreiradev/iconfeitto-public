package br.com.jhoneferreiradev.iconfeitto.api.documentacao.estoque;

import br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.estoque.movimentacao.CompraDTOEntrada;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.saida.estoque.movimentacao.CompraDTOSaida;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.parameters.RequestBody;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;

import java.util.List;

@Tag(name = "Compra", description = "Gerenciamento das compras")
public interface CompraControllerDoc {

    @Operation(
            summary = "Adiciona uma nova compra",
            description = "Adiciona uma nova compra ao sistema")
    ResponseEntity<CompraDTOSaida> adicionar(
            @RequestBody(
                    description = "Dados para a criação de uma nova compra",
                    useParameterTypeSchema = true) CompraDTOEntrada dto);

    @Operation(
            summary = "Lista as compras",
            description = "Retorna a lista de todas as compras cadastradas")
    ResponseEntity<List<CompraDTOSaida>> listar();

    @Operation(
            summary = "Busca uma compra por ID",
            description = "Retorna os detalhes de uma compra específica pelo seu ID")
    ResponseEntity<CompraDTOSaida> buscarPorId(
            @Parameter(
                    description = "ID único da compra cadastrada",
                    example = "42",
                    required = true) Long id);

    @Operation(
            summary = "Atualiza uma compra",
            description = "Atualiza os detalhes de uma compra existente pelo seu ID. " +
                    "Atributos nulos ou não informados, serão ignorados e não sobrescreverão os valores existentes")
    ResponseEntity<CompraDTOSaida> atualizar(
            @Parameter(
                    description = "ID único da compra cadastrada",
                    example = "42",
                    required = true) Long id,
            @RequestBody(
                    description = "Dados para atualização de uma compra. " +
                            "Atributos nulos ou não informados, serão ignorados e não sobrescreverão os valores existentes",
                    useParameterTypeSchema = true) CompraDTOEntrada dto);

}
