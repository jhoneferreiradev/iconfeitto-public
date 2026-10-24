package br.com.jhoneferreiradev.iconfeitto.config.autenticador.mock;

import br.com.jhoneferreiradev.iconfeitto.config.autenticador.AutenticadorService;
import br.com.jhoneferreiradev.iconfeitto.dominio.excecao.IConfeittoException;
import br.com.jhoneferreiradev.iconfeitto.dominio.servico.empresa.usuario.UsuarioService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.Base64;

@Slf4j
public class AutenticadorMockService implements AutenticadorService {

    private UsuarioService usuarioService;

    public AutenticadorMockService(UsuarioService usuarioService) {
        this.usuarioService = usuarioService;
    }

    /**
     * Método de autenticação mock para fins de teste.
     * <p>
     *     Troque o valor de teste@teste.com por um e-mail válido de um usuário cadastrado no banco de dados para simular a autenticação.
     * </p>
     * @param token
     */
    @Override
    public void autenticar(String token) {
        log.info("\n\n Autenticador de teste em utilização !!! \n\n");
        var email = decodificarTokenParaEmail(token);
        var usuario = usuarioService
                .buscarPorEmailComConfeitaria(email)
                .orElseThrow(() -> new IConfeittoException("Acesso não autorizado", HttpStatus.UNAUTHORIZED));
        var usuarioAutenticado = new UsernamePasswordAuthenticationToken(usuario, null, usuario.getAuthorities());
        SecurityContextHolder.getContext().setAuthentication(usuarioAutenticado);
    }

    public static String decodificarTokenParaEmail(String token) {
        byte[] bytes = Base64.getDecoder().decode(token);
        return new String(bytes, java.nio.charset.StandardCharsets.UTF_8);
    }
}
