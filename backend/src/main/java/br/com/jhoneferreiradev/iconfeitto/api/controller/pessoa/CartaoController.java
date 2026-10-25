package br.com.jhoneferreiradev.iconfeitto.api.controller.pessoa;

import br.com.jhoneferreiradev.iconfeitto.api.controller.ControllerBase;
import br.com.jhoneferreiradev.iconfeitto.api.documentacao.pessoa.CartaoControllerDoc;
import br.com.jhoneferreiradev.iconfeitto.api.grupovalidacao.ValidacaoInclusao;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.pessoa.CartaoDTOEntrada;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.saida.pessoa.CartaoDTOSaida;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.cartao.Cartao;
import br.com.jhoneferreiradev.iconfeitto.dominio.servico.pessoa.CartaoService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/cartoes")
public class CartaoController
        extends ControllerBase<Cartao, CartaoDTOSaida, CartaoDTOEntrada>
        implements CartaoControllerDoc {

    @Autowired
    public CartaoController(CartaoService cartaoService) {
        super(cartaoService, Cartao.class, CartaoDTOSaida.class);
    }

    @Transactional
    @PostMapping
    public ResponseEntity<CartaoDTOSaida> adicionar(@RequestBody @Validated(ValidacaoInclusao.class) CartaoDTOEntrada dto) {
        return super.adicionar(dto);
    }

    @GetMapping
    public ResponseEntity<List<CartaoDTOSaida>> listar() {
        return super.listar();
    }

    @GetMapping("/{id}")
    public ResponseEntity<CartaoDTOSaida> buscarPorId(@PathVariable Long id) {
        return super.buscarPorId(id);
    }

    @Transactional
    @PatchMapping("/{id}")
    public ResponseEntity<CartaoDTOSaida> atualizar(@PathVariable Long id, @RequestBody CartaoDTOEntrada dto) {
        return super.atualizar(id, dto);
    }

}
