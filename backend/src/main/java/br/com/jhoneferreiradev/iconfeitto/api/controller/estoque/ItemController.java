package br.com.jhoneferreiradev.iconfeitto.api.controller.estoque;

import br.com.jhoneferreiradev.iconfeitto.api.documentacao.estoque.ItemControllerDoc;
import br.com.jhoneferreiradev.iconfeitto.api.grupovalidacao.ValidacaoInclusao;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.conversordeobjeto.ConversorObjetos;
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
public class ItemController implements ItemControllerDoc {

    @Autowired
    private ItemService itemService;

    @Transactional
    @PostMapping
    public ResponseEntity<ItemDTOSaida> adicionar(@RequestBody @Validated(ValidacaoInclusao.class) ItemDTOEntrada itemDTOEntrada) {
        Item item = ConversorObjetos.converter(itemDTOEntrada, ItemDTOEntrada.class, Item.class);
        item = itemService.salvar(item);
        ItemDTOSaida saida = ConversorObjetos.converter(item, Item.class, ItemDTOSaida.class);
        return ResponseEntity.ok(saida);
    }

    @GetMapping
    public ResponseEntity<List<ItemDTOSaida>> listar() {
        List<Item> itens = itemService.listarTodos();
        List<ItemDTOSaida> saidas = itens.stream().map(item -> ConversorObjetos.converter(item, Item.class, ItemDTOSaida.class)).toList();
        return ResponseEntity.ok(saidas);
    }

    @GetMapping("/{id}")
    public ResponseEntity<ItemDTOSaida> buscarPorId(@PathVariable Long id) {
        Item item = itemService.getPorId(id);
        ItemDTOSaida saida = ConversorObjetos.converter(item, Item.class, ItemDTOSaida.class);
        return ResponseEntity.ok(saida);
    }

    @Transactional
    @PatchMapping("/{id}")
    public ResponseEntity<ItemDTOSaida> atualizar(@PathVariable Long id, @RequestBody ItemDTOEntrada itemDTOEntrada) {
        Item itemExistente = itemService.getPorId(id);

        ConversorObjetos.atualizarIgnorandoNulos(itemDTOEntrada, itemExistente);

        Item itemAtualizado = itemService.salvar(itemExistente);
        ItemDTOSaida saida = ConversorObjetos.converter(itemAtualizado, Item.class, ItemDTOSaida.class);
        return ResponseEntity.ok(saida);
    }

}
