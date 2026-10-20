package br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.empresa.usuario;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.empresa.usuario.Usuario;
import br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.base.RepositorioBaseComConfeitariaRepository;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface UsuarioRepository extends
        JpaRepository<Usuario, Long>,
        RepositorioBaseComConfeitariaRepository<Usuario, Long> {

}
