package br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.estoque;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao.venda.Venda;
import br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.base.RepositorioBaseComConfeitariaRepository;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface VendaRepository extends
        JpaRepository<Venda, Long>,
        RepositorioBaseComConfeitariaRepository<Venda, Long> {
}
