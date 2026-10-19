package br.com.jhoneferreiradev.iconfeitto.dominio.repositorio;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao.saidaconsumo.SaidaConsumo;
import br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.base.RepositorioBaseComConfeitariaRepository;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface SaidaConsumoRepository extends JpaRepository<SaidaConsumo, Long>, RepositorioBaseComConfeitariaRepository<SaidaConsumo, Long> {
}
