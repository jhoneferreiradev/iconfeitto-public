package br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.base;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.confeitaria.Confeitaria;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface RepositorioBaseAtivavelRepository<T, ID> {

    List<T> findAllByAtivoTrueAndConfeitaria(Confeitaria confeitaria);
}
