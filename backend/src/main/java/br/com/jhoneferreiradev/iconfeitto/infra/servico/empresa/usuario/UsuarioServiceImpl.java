package br.com.jhoneferreiradev.iconfeitto.infra.servico.empresa.usuario;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.empresa.usuario.Usuario;
import br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.empresa.usuario.UsuarioRepository;
import br.com.jhoneferreiradev.iconfeitto.dominio.servico.empresa.usuario.UsuarioService;
import br.com.jhoneferreiradev.iconfeitto.infra.servico.base.BaseServiceImpl;
import org.springframework.stereotype.Service;

@Service
public class UsuarioServiceImpl extends BaseServiceImpl<Usuario> implements UsuarioService {

    public UsuarioServiceImpl(UsuarioRepository repository) {
        super(repository, "Usuário");
    }

}
