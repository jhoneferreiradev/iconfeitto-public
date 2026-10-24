package br.com.jhoneferreiradev.iconfeitto.infra.servico.empresa.usuario;

import br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.empresa.confeitaria.NovaConfeitariaDTOEntrada;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.empresa.confeitaria.Confeitaria;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.empresa.usuario.PerfilUsuario;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.empresa.usuario.Usuario;
import br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.empresa.usuario.UsuarioRepository;
import br.com.jhoneferreiradev.iconfeitto.dominio.servico.empresa.usuario.UsuarioService;
import br.com.jhoneferreiradev.iconfeitto.infra.servico.base.BaseServiceImpl;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class UsuarioServiceImpl extends BaseServiceImpl<Usuario> implements UsuarioService {

    public UsuarioServiceImpl(UsuarioRepository repository) {
        super(repository, "Usuário");
    }

    @Override
    public Optional<Usuario> buscarPorEmailComConfeitaria(String email) {
        return getRepository().findByEmail(email);
    }

    @Override
    public UsuarioRepository getRepository() {
        return (UsuarioRepository) super.getRepository();
    }

    @Override
    public void adicionarPrimeiroUsuarioDaConfeitaria(NovaConfeitariaDTOEntrada dtoNovaConfeitaria, Confeitaria confeitaria) {
        Usuario usuario = new Usuario();
        usuario.setEmail(dtoNovaConfeitaria.emailUsuarioMaster());
        usuario.setNome(dtoNovaConfeitaria.nomeUsuarioMaster());
        usuario.setConfeitaria(confeitaria);
        usuario.setPerfil(PerfilUsuario.ADMINISTRADOR);
        getRepository().save(usuario);
    }

}
