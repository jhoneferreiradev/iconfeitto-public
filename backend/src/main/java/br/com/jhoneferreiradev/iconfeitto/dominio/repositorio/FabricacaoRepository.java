package br.com.jhoneferreiradev.iconfeitto.dominio.repositorio;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao.fabricacao.Fabricacao;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface FabricacaoRepository extends JpaRepository<Fabricacao, Long> {
}
