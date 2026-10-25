package br.com.jhoneferreiradev.iconfeitto.api.controller.estoque;

import br.com.jhoneferreiradev.iconfeitto.api.controller.ControllerBase;
import br.com.jhoneferreiradev.iconfeitto.api.documentacao.estoque.UnidadeMedidaControllerDoc;
import br.com.jhoneferreiradev.iconfeitto.api.grupovalidacao.ValidacaoInclusao;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.estoque.unidademedida.UnidadeMedidaDTOEntrada;
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
public class UnidadeMedidaController
        extends ControllerBase<UnidadeMedida, UnidadeMedidaDTOSaida, UnidadeMedidaDTOEntrada>
        implements UnidadeMedidaControllerDoc {

    @Autowired
    public UnidadeMedidaController(UnidadeMedidaService unidadeMedidaService) {
        super(unidadeMedidaService, UnidadeMedida.class, UnidadeMedidaDTOSaida.class);
    }

    @Transactional
    @PostMapping
    @Override
    public ResponseEntity<UnidadeMedidaDTOSaida> adicionar(@RequestBody @Validated(ValidacaoInclusao.class) UnidadeMedidaDTOEntrada dto) {
        return super.adicionar(dto);
    }

    @GetMapping
    public ResponseEntity<List<UnidadeMedidaDTOSaida>> listar() {
        return super.listar();
    }

    @GetMapping("/{id}")
    public ResponseEntity<UnidadeMedidaDTOSaida> buscarPorId(@PathVariable Long id) {
        return super.buscarPorId(id);
    }

    @Transactional
    @PatchMapping("/{id}")
    public ResponseEntity<UnidadeMedidaDTOSaida> atualizar(@PathVariable Long id, @RequestBody UnidadeMedidaDTOEntrada dto) {
        return super.atualizar(id, dto);
    }

}
