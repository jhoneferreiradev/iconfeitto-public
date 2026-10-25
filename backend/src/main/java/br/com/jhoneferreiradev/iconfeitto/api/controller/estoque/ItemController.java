package br.com.jhoneferreiradev.iconfeitto.api.controller.estoque;

import br.com.jhoneferreiradev.iconfeitto.api.controller.ControllerBase;
import br.com.jhoneferreiradev.iconfeitto.api.documentacao.estoque.ItemControllerDoc;
import br.com.jhoneferreiradev.iconfeitto.api.grupovalidacao.ValidacaoInclusao;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.estoque.item.ItemDTOEntrada;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.saida.estoque.item.ItemDTOSaida;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.item.Item;
import br.com.jhoneferreiradev.iconfeitto.dominio.servico.estoque.ItemService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/itens")
public class ItemController
        extends ControllerBase<Item, ItemDTOSaida, ItemDTOEntrada>
        implements ItemControllerDoc {

    @Autowired
    public ItemController(ItemService itemService) {
        super(itemService, Item.class, ItemDTOSaida.class);
    }

    @Transactional
    @PostMapping
    public ResponseEntity<ItemDTOSaida> adicionar(@RequestBody @Validated(ValidacaoInclusao.class) ItemDTOEntrada itemDTOEntrada) {
        return super.adicionar(itemDTOEntrada);
    }

    @GetMapping
    public ResponseEntity<List<ItemDTOSaida>> listar() {
        return super.listar();
    }

    @GetMapping("/{id}")
    public ResponseEntity<ItemDTOSaida> buscarPorId(@PathVariable Long id) {
        return super.buscarPorId(id);
    }

    @Transactional
    @PatchMapping("/{id}")
    public ResponseEntity<ItemDTOSaida> atualizar(@PathVariable Long id, @RequestBody ItemDTOEntrada itemDTOEntrada) {
        return super.atualizar(id, itemDTOEntrada);
    }

}
