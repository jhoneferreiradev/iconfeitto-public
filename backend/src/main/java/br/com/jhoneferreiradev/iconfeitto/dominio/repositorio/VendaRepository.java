package br.com.jhoneferreiradev.iconfeitto.dominio.repositorio;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao.venda.Venda;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface VendaRepository extends JpaRepository<Venda, Long> {
}
