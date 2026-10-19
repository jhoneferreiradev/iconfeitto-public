package br.com.jhoneferreiradev.iconfeitto.dominio.repositorio;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.bandeiracartao.BandeiraCartao;
import br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.base.RepositorioBaseAtivavelRepository;
import br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.base.RepositorioBaseComConfeitariaRepository;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface BandeiraCartaoRepository extends
        JpaRepository<BandeiraCartao, Long>,
        RepositorioBaseComConfeitariaRepository<BandeiraCartao, Long>,
        RepositorioBaseAtivavelRepository<BandeiraCartao, Long> {
}
