package br.com.jhoneferreiradev.iconfeitto.api.documentacao.pessoa;

import br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.pessoa.BandeiraCartaoDTOEntrada;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.saida.pessoa.BandeiraCartaoDTOSaida;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.parameters.RequestBody;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;

import java.util.List;

@Tag(name = "Bandeira de Cartão", description = "Gerenciamento das bandeiras de cartão")
public interface BandeiraCartaoControllerDoc {

    @Operation(
            summary = "Adiciona uma nova bandeira de cartão",
            description = "Adiciona uma nova bandeira de cartão ao sistema")
    ResponseEntity<BandeiraCartaoDTOSaida> adicionar(
            @RequestBody(
                    description = "Dados para a criação de uma nova bandeira de cartão",
                    useParameterTypeSchema = true) BandeiraCartaoDTOEntrada dto);

    @Operation(
            summary = "Lista as bandeiras de cartão",
            description = "Retorna a lista de todas as bandeiras de cartão cadastradas")
    ResponseEntity<List<BandeiraCartaoDTOSaida>> listar();

    @Operation(
            summary = "Busca uma bandeira de cartão por ID",
            description = "Retorna os detalhes de uma bandeira de cartão específica pelo seu ID")
    ResponseEntity<BandeiraCartaoDTOSaida> buscarPorId(
            @Parameter(
                    description = "ID único da bandeira de cartão cadastrada",
                    example = "42",
                    required = true) Long id);

    @Operation(
            summary = "Atualiza uma bandeira de cartão",
            description = "Atualiza os detalhes de uma bandeira de cartão existente pelo seu ID. " +
                    "Atributos nulos ou não informados, serão ignorados e não sobrescreverão os valores existentes")
    ResponseEntity<BandeiraCartaoDTOSaida> atualizar(
            @Parameter(
                    description = "ID único da bandeira de cartão cadastrada",
                    example = "42",
                    required = true) Long id,
            @RequestBody(
                    description = "Dados para atualização de uma bandeira de cartão. " +
                            "Atributos nulos ou não informados, serão ignorados e não sobrescreverão os valores existentes",
                    useParameterTypeSchema = true) BandeiraCartaoDTOEntrada dto);

}
