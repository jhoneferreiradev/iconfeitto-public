package br.com.jhoneferreiradev.iconfeitto.api.documentacao.empresa;

import br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.empresa.confeitaria.ConfeitariaDTOEntrada;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.empresa.confeitaria.NovaConfeitariaDTOEntrada;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.saida.empresa.confeitaria.ConfeitariaDTOSaida;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.parameters.RequestBody;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;

@Tag(name = "Confeitaria", description = "Gerenciamento das confeitarias")
public interface ConfeitariaControllerDoc {

    @Operation(
            summary = "Adiciona uma nova confeitaria",
            description = "Adiciona uma nova confeitaria ao sistema"
    )
    ResponseEntity<ConfeitariaDTOSaida> adicionar(
            @RequestBody(
                    description = "Dados para a criação de uma nova confeitaria",
                    useParameterTypeSchema = true) NovaConfeitariaDTOEntrada novaConfeitariaDTOEntrada);

    @Operation(summary = "Busca uma confeitaria por ID", description = "Retorna os detalhes de uma confeitaria específica pelo seu ID")
    ResponseEntity<ConfeitariaDTOSaida> buscarPorId(
            @Parameter(description = "ID único da confeitaria cadastrada",
                    example = "42", required = true) Long id);

    @Operation(
            summary = "Atualiza uma confeitaria",
            description = "Atualiza os detalhes de uma confeitaria existente pelo seu ID. " +
                    "Atributos nulos ou não informados, serão ignorados e não sobrescreverão os valores existentes")
    ResponseEntity<ConfeitariaDTOSaida> atualizar(
            @Parameter(
                    description = "ID único da confeitaria cadastrada",
                    example = "42",
                    required = true) Long id,
            @RequestBody(description = "Dados para atualização de uma confeitaria. " +
                    "Atributos nulos ou não informados, serão ignorados e não sobrescreverão os valores existentes",
                    useParameterTypeSchema = true) ConfeitariaDTOEntrada confeitariaDTOEntrada);

}
