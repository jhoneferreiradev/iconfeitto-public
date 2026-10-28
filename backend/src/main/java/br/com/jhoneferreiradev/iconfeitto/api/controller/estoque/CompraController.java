package br.com.jhoneferreiradev.iconfeitto.api.controller.estoque;

import br.com.jhoneferreiradev.iconfeitto.api.controller.ControllerBase;
import br.com.jhoneferreiradev.iconfeitto.api.documentacao.estoque.CompraControllerDoc;
import br.com.jhoneferreiradev.iconfeitto.api.grupovalidacao.ValidacaoInclusao;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.estoque.movimentacao.CompraDTOEntrada;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.saida.estoque.movimentacao.CompraDTOSaida;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao.compra.Compra;
import br.com.jhoneferreiradev.iconfeitto.dominio.servico.estoque.CompraService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/compras")
public class CompraController
        extends ControllerBase<Compra, CompraDTOSaida, CompraDTOEntrada>
        implements CompraControllerDoc {

    @Autowired
    public CompraController(CompraService compraService) {
        super(compraService, Compra.class, CompraDTOSaida.class);
    }

    @Transactional
    @PostMapping
    public ResponseEntity<CompraDTOSaida> adicionar(@RequestBody @Validated(ValidacaoInclusao.class) CompraDTOEntrada compraDTOEntrada) {
        return super.adicionar(compraDTOEntrada);
    }

    @GetMapping
    public ResponseEntity<List<CompraDTOSaida>> listar() {
        return super.listar();
    }

    @GetMapping("/{id}")
    public ResponseEntity<CompraDTOSaida> buscarPorId(@PathVariable Long id) {
        return super.buscarPorId(id);
    }

    @Transactional
    @PatchMapping("/{id}")
    public ResponseEntity<CompraDTOSaida> atualizar(@PathVariable Long id, @RequestBody CompraDTOEntrada compraDTOEntrada) {
        return super.atualizar(id, compraDTOEntrada);
    }

}
