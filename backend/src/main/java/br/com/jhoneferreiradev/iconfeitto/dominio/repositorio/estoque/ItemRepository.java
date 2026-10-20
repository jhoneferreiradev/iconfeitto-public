package br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.estoque;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.item.Item;
import br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.base.RepositorioBaseAtivavelRepository;
import br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.base.RepositorioBaseComConfeitariaRepository;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ItemRepository extends
        JpaRepository<Item, Long>,
        RepositorioBaseComConfeitariaRepository<Item, Long>,
        RepositorioBaseAtivavelRepository<Item, Long> {
}
