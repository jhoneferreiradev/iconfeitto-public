package br.com.jhoneferreiradev.iconfeitto.infra.servico.estoque;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.item.Item;
import br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.estoque.ItemRepository;
import br.com.jhoneferreiradev.iconfeitto.dominio.servico.estoque.ItemService;
import br.com.jhoneferreiradev.iconfeitto.infra.servico.base.BaseServiceImpl;
import org.springframework.stereotype.Service;

@Service
public class ItemServiceImpl extends BaseServiceImpl<Item> implements ItemService {

    public ItemServiceImpl(ItemRepository repository) {
        super(repository, "Item");
    }

}
