package br.com.jhoneferreiradev.iconfeitto.api.controller.estoque;

import br.com.jhoneferreiradev.iconfeitto.api.controller.ControllerBase;
import br.com.jhoneferreiradev.iconfeitto.api.documentacao.estoque.VendaControllerDoc;
import br.com.jhoneferreiradev.iconfeitto.api.grupovalidacao.ValidacaoInclusao;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.conversordeobjeto.ConversorObjetos;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.estoque.movimentacao.AtualizacaoStatusVendaDTOEntrada;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.estoque.movimentacao.VendaDTOEntrada;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.saida.estoque.movimentacao.VendaDTOSaida;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao.venda.Venda;
import br.com.jhoneferreiradev.iconfeitto.dominio.servico.estoque.VendaService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/vendas")
public class VendaController
        extends ControllerBase<Venda, VendaDTOSaida, VendaDTOEntrada>
        implements VendaControllerDoc {

    @Autowired
    public VendaController(VendaService vendaService) {
        super(vendaService, Venda.class, VendaDTOSaida.class);
    }

    @Transactional
    @PostMapping
    public ResponseEntity<VendaDTOSaida> adicionar(@RequestBody @Validated(ValidacaoInclusao.class) VendaDTOEntrada vendaDTOEntrada) {
        return super.adicionar(vendaDTOEntrada);
    }

    @GetMapping
    public ResponseEntity<List<VendaDTOSaida>> listar() {
        return super.listar();
    }

    @GetMapping("/{id}")
    public ResponseEntity<VendaDTOSaida> buscarPorId(@PathVariable Long id) {
        return super.buscarPorId(id);
    }

    @Transactional
    @PatchMapping("/{id}")
    public ResponseEntity<VendaDTOSaida> atualizar(@PathVariable Long id, @RequestBody VendaDTOEntrada vendaDTOEntrada) {
        return super.atualizar(id, vendaDTOEntrada);
    }

    @Transactional
    @PatchMapping("/{id}/status")
    public ResponseEntity<VendaDTOSaida> atualizarStatus(@PathVariable Long id, @RequestBody @Valid AtualizacaoStatusVendaDTOEntrada vendaDTOEntrada) {
        final Venda vendaAtualizada = ((VendaService) getServicoBase())
                .atualizarStatus(
                        new VendaService.AtualizacaoStatusDTO(
                                id,
                                vendaDTOEntrada.getStatusVenda(),
                                vendaDTOEntrada.getDataEntrega()
                        ));
        final VendaDTOSaida dtoConvertido = ConversorObjetos.converter(vendaAtualizada, Venda.class, VendaDTOSaida.class);
        return ResponseEntity.ok(dtoConvertido);
    }

}
