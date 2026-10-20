package br.com.jhoneferreiradev.iconfeitto.infra.servico.estoque;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.item.PrecoItem;
import br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.estoque.PrecoItemRepository;
import br.com.jhoneferreiradev.iconfeitto.dominio.servico.estoque.PrecoItemService;
import br.com.jhoneferreiradev.iconfeitto.infra.servico.base.BaseServiceImpl;
import org.springframework.stereotype.Service;

@Service
public class PrecoItemServiceImpl extends BaseServiceImpl<PrecoItem> implements PrecoItemService {

    public PrecoItemServiceImpl(PrecoItemRepository repository) {
        super(repository, "Preço do item");
    }

}
