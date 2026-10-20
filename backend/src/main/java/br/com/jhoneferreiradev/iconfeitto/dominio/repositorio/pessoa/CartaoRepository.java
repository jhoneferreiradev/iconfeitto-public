package br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.pessoa;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.cartao.Cartao;
import br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.base.RepositorioBaseAtivavelRepository;
import br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.base.RepositorioBaseComConfeitariaRepository;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface CartaoRepository extends
        JpaRepository<Cartao, Long>,
        RepositorioBaseComConfeitariaRepository<Cartao, Long>,
        RepositorioBaseAtivavelRepository<Cartao, Long> {
}
