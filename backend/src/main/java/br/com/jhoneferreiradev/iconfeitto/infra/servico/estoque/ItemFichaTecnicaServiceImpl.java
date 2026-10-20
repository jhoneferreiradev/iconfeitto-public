package br.com.jhoneferreiradev.iconfeitto.infra.servico.estoque;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.item.ItemFichaTecnica;
import br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.estoque.ItemFichaTecnicaRepository;
import br.com.jhoneferreiradev.iconfeitto.dominio.servico.estoque.ItemFichaTecnicaService;
import br.com.jhoneferreiradev.iconfeitto.infra.servico.base.BaseServiceImpl;
import org.springframework.stereotype.Service;

@Service
public class ItemFichaTecnicaServiceImpl extends BaseServiceImpl<ItemFichaTecnica> implements ItemFichaTecnicaService {

    public ItemFichaTecnicaServiceImpl(ItemFichaTecnicaRepository repository) {
        super(repository, "Item ficha técnica");
    }

}
