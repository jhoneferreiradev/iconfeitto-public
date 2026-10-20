package br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.empresa.confeitaria;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.empresa.confeitaria.Confeitaria;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ConfeitariaRepository extends JpaRepository<Confeitaria, Long> {
}
