package br.com.jhoneferreiradev.iconfeitto.dominio.servico.empresa.usuario;

import br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.empresa.confeitaria.NovaConfeitariaDTOEntrada;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.empresa.confeitaria.Confeitaria;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.empresa.usuario.Usuario;
import br.com.jhoneferreiradev.iconfeitto.dominio.servico.base.ServicoBase;
import java.util.Optional;

public interface UsuarioService extends ServicoBase<Usuario> {

    Optional<Usuario> buscarPorEmailComConfeitaria(String email);

    void adicionarPrimeiroUsuarioDaConfeitaria(NovaConfeitariaDTOEntrada dtoNovaConfeitaria, Confeitaria confeitaria);
}
