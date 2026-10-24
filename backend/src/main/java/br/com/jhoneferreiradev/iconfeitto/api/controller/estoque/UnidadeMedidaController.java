package br.com.jhoneferreiradev.iconfeitto.api.controller.estoque;

import br.com.jhoneferreiradev.iconfeitto.api.documentacao.estoque.UnidadeMedidaControllerDoc;
import br.com.jhoneferreiradev.iconfeitto.api.grupovalidacao.ValidacaoInclusao;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.conversordeobjeto.ConversorObjetos;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.estoque.UnidadeMedidaDTOEntrada;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.saida.estoque.UnidadeMedidaDTOSaida;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.unidademedida.UnidadeMedida;
import br.com.jhoneferreiradev.iconfeitto.dominio.servico.estoque.UnidadeMedidaService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/unidades-medidas")
public class UnidadeMedidaController implements UnidadeMedidaControllerDoc {

    @Autowired
    private UnidadeMedidaService unidadeMedidaService;

    @Transactional
    @PostMapping
    public ResponseEntity<UnidadeMedidaDTOSaida> adicionar(@RequestBody @Validated(ValidacaoInclusao.class) UnidadeMedidaDTOEntrada dtoNovaUnidadeMedida) {
        UnidadeMedida unidadeMedida = ConversorObjetos.converter(dtoNovaUnidadeMedida, UnidadeMedidaDTOEntrada.class, UnidadeMedida.class);
        unidadeMedida = unidadeMedidaService.salvar(unidadeMedida);
        UnidadeMedidaDTOSaida saida = ConversorObjetos.converter(unidadeMedida, UnidadeMedida.class, UnidadeMedidaDTOSaida.class);
        return ResponseEntity.ok(saida);
    }

    @GetMapping
    public ResponseEntity<List<UnidadeMedidaDTOSaida>> listar() {
        List<UnidadeMedida> unidadesMedida = unidadeMedidaService.listarTodos();
        List<UnidadeMedidaDTOSaida> saidas = unidadesMedida.stream().map(unidadeMedida -> ConversorObjetos.converter(unidadeMedida, UnidadeMedida.class, UnidadeMedidaDTOSaida.class)).toList();
        return ResponseEntity.ok(saidas);
    }

    @GetMapping("/{id}")
    public ResponseEntity<UnidadeMedidaDTOSaida> buscarPorId(@PathVariable Long id) {
        UnidadeMedida unidadeMedida = unidadeMedidaService.getPorId(id);
        UnidadeMedidaDTOSaida saida = ConversorObjetos.converter(unidadeMedida, UnidadeMedida.class, UnidadeMedidaDTOSaida.class);
        return ResponseEntity.ok(saida);
    }

    @Transactional
    @PatchMapping("/{id}")
    public ResponseEntity<UnidadeMedidaDTOSaida> atualizar(@PathVariable Long id, @RequestBody UnidadeMedidaDTOEntrada dtoAtualizacao) {
        UnidadeMedida unidadeMedidaExistente = unidadeMedidaService.getPorId(id);

        ConversorObjetos.atualizarIgnorandoNulos(dtoAtualizacao, unidadeMedidaExistente);

        UnidadeMedida unidadeMedidaAtualizado = unidadeMedidaService.salvar(unidadeMedidaExistente);
        UnidadeMedidaDTOSaida saida = ConversorObjetos.converter(unidadeMedidaAtualizado, UnidadeMedida.class, UnidadeMedidaDTOSaida.class);
        return ResponseEntity.ok(saida);
    }

}
