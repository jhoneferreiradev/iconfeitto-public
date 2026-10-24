package br.com.jhoneferreiradev.iconfeitto.config.autenticador.firebase;

import br.com.jhoneferreiradev.iconfeitto.config.autenticador.AutenticadorService;
import br.com.jhoneferreiradev.iconfeitto.config.firebase.FirebaseConfig;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.empresa.usuario.Usuario;
import br.com.jhoneferreiradev.iconfeitto.dominio.excecao.IConfeittoException;
import br.com.jhoneferreiradev.iconfeitto.dominio.servico.empresa.usuario.UsuarioService;
import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.FirebaseToken;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.Optional;

public class AutenticadorFirebaseService implements AutenticadorService {

    private final FirebaseConfig firebaseConfig;
    private final UsuarioService usuarioService;

    public AutenticadorFirebaseService(FirebaseConfig firebaseConfig, UsuarioService usuarioService) {
        this.firebaseConfig = firebaseConfig;
        this.usuarioService = usuarioService;
    }

    public Optional<FirebaseToken> verificarPorIdToken(String idTokenFirebase) {
        return firebaseConfig.getFirebaseAuth().map(auth -> {
            try {
                return auth.verifyIdToken(idTokenFirebase);
            } catch (FirebaseAuthException e) {
                return null;
            }
        });
    }

    @Override
    public void autenticar(String idTokenFirebase) {

        Optional<FirebaseToken> firebaseToken = verificarPorIdToken(idTokenFirebase);

        String email = firebaseToken
                .map(FirebaseToken::getEmail)
                .orElseThrow(() -> new IConfeittoException("Acesso não autorizado", HttpStatus.UNAUTHORIZED));

        Usuario usuario = usuarioService
                .buscarPorEmailComConfeitaria(email)
                .orElseThrow(() -> new IConfeittoException("Acesso não autorizado", HttpStatus.UNAUTHORIZED));

        var usuarioAutenticado = new UsernamePasswordAuthenticationToken(usuario, null, usuario.getAuthorities());

        SecurityContextHolder.getContext().setAuthentication(usuarioAutenticado);
    }
}
