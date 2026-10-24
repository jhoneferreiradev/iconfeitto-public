package br.com.jhoneferreiradev.iconfeitto.api.controller.pessoa;

import br.com.jhoneferreiradev.iconfeitto.api.documentacao.pessoa.CartaoControllerDoc;
import br.com.jhoneferreiradev.iconfeitto.api.grupovalidacao.ValidacaoInclusao;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.conversordeobjeto.ConversorObjetos;
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
public class CartaoController implements CartaoControllerDoc {

    @Autowired
    private CartaoService cartaoService;

    @Transactional
    @PostMapping
    public ResponseEntity<CartaoDTOSaida> adicionar(@RequestBody @Validated(ValidacaoInclusao.class) CartaoDTOEntrada dtoNovaCartao) {
        Cartao cartao = ConversorObjetos.converter(dtoNovaCartao, CartaoDTOEntrada.class, Cartao.class);
        cartao = cartaoService.salvar(cartao);
        CartaoDTOSaida saida = ConversorObjetos.converter(cartao, Cartao.class, CartaoDTOSaida.class);
        return ResponseEntity.ok(saida);
    }

    @GetMapping
    public ResponseEntity<List<CartaoDTOSaida>> listar() {
        List<Cartao> cartoes = cartaoService.listarTodos();
        List<CartaoDTOSaida> saidas = cartoes.stream().map(cartao -> ConversorObjetos.converter(cartao, Cartao.class, CartaoDTOSaida.class)).toList();
        return ResponseEntity.ok(saidas);
    }

    @GetMapping("/{id}")
    public ResponseEntity<CartaoDTOSaida> buscarPorId(@PathVariable Long id) {
        Cartao cartao = cartaoService.getPorId(id);
        CartaoDTOSaida saida = ConversorObjetos.converter(cartao, Cartao.class, CartaoDTOSaida.class);
        return ResponseEntity.ok(saida);
    }

    @Transactional
    @PatchMapping("/{id}")
    public ResponseEntity<CartaoDTOSaida> atualizar(@PathVariable Long id, @RequestBody CartaoDTOEntrada dtoAtualizacao) {
        Cartao cartaoExistente = cartaoService.getPorId(id);

        ConversorObjetos.atualizarIgnorandoNulos(dtoAtualizacao, cartaoExistente);

        Cartao cartaoAtualizado = cartaoService.salvar(cartaoExistente);
        CartaoDTOSaida saida = ConversorObjetos.converter(cartaoAtualizado, Cartao.class, CartaoDTOSaida.class);
        return ResponseEntity.ok(saida);
    }

}
