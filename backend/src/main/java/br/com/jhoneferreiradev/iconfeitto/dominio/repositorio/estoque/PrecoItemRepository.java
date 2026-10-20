package br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.estoque;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.item.PrecoItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface PrecoItemRepository extends JpaRepository<PrecoItem, Long> {
}
