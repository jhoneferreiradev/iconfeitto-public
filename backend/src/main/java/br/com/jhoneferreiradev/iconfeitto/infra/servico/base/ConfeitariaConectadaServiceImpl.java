package br.com.jhoneferreiradev.iconfeitto.infra.servico.base;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.empresa.confeitaria.Confeitaria;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.empresa.usuario.Usuario;
import br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.base.ConfeitariaConectadaService;
import br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.empresa.usuario.UsuarioRepository;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class ConfeitariaConectadaServiceImpl implements ConfeitariaConectadaService {

    private final UsuarioRepository usuarioRepository;

    public ConfeitariaConectadaServiceImpl(UsuarioRepository usuarioRepository) {
        this.usuarioRepository = usuarioRepository;
    }

    @Override
    public Optional<Confeitaria> getConfeitariaConectada() {
        var auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) {
            return Optional.empty();
        }

        Object principal = auth.getPrincipal();
        if (!(principal instanceof Usuario usuario)) {
            return Optional.empty();
        }

        return Optional.of(usuario.getConfeitaria());
    }

}