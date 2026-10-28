package br.com.jhoneferreiradev.iconfeitto.api.documentacao.estoque;

import br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.estoque.movimentacao.VendaDTOEntrada;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.saida.estoque.movimentacao.VendaDTOSaida;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.parameters.RequestBody;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;

import java.util.List;

@Tag(name = "Venda", description = "Gerenciamento das vendas")
public interface VendaControllerDoc {

    @Operation(
            summary = "Adiciona uma nova venda",
            description = "Adiciona uma nova venda ao sistema")
    ResponseEntity<VendaDTOSaida> adicionar(
            @RequestBody(
                    description = "Dados para a criação de uma nova venda",
                    useParameterTypeSchema = true) VendaDTOEntrada dto);

    @Operation(
            summary = "Lista as vendas",
            description = "Retorna a lista de todas as vendas cadastradas")
    ResponseEntity<List<VendaDTOSaida>> listar();

    @Operation(
            summary = "Busca uma venda por ID",
            description = "Retorna os detalhes de uma venda específica pelo seu ID")
    ResponseEntity<VendaDTOSaida> buscarPorId(
            @Parameter(
                    description = "ID único da venda cadastrada",
                    example = "42",
                    required = true) Long id);

    @Operation(
            summary = "Atualiza uma venda",
            description = "Atualiza os detalhes de uma venda existente pelo seu ID. " +
                    "Atributos nulos ou não informados, serão ignorados e não sobrescreverão os valores existentes")
    ResponseEntity<VendaDTOSaida> atualizar(
            @Parameter(
                    description = "ID único da venda cadastrada",
                    example = "42",
                    required = true) Long id,
            @RequestBody(
                    description = "Dados para atualização de uma venda. " +
                            "Atributos nulos ou não informados, serão ignorados e não sobrescreverão os valores existentes",
                    useParameterTypeSchema = true) VendaDTOEntrada dto);

}
