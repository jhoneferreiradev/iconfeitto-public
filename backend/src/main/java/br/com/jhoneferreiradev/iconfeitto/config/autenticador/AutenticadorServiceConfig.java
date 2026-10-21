package br.com.jhoneferreiradev.iconfeitto.config.autenticador;

import br.com.jhoneferreiradev.iconfeitto.config.autenticador.mock.AutenticadorMockService;
import br.com.jhoneferreiradev.iconfeitto.config.firebase.FirebaseConfig;
import br.com.jhoneferreiradev.iconfeitto.config.autenticador.firebase.AutenticadorFirebaseService;
import br.com.jhoneferreiradev.iconfeitto.dominio.servico.empresa.usuario.UsuarioService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class AutenticadorServiceConfig {

    @Autowired
    private FirebaseConfig firebaseConfig;
    @Autowired
    private UsuarioService usuarioService;


    /**
     * Configura o serviço de autenticação usando Firebase.
     * <p>
     * Você pode usar esta configuração mas precisará criar uma conta no Firebase e gerar um arquivo de chave de serviço (serviceAccountKey.json) para autenticação.
     * </p>
     *
     * @return uma instância de FirebaseTokenService
     */
    @Bean
    public AutenticadorFirebaseService autenticadorFirebase() {
        return new AutenticadorFirebaseService(firebaseConfig, usuarioService);
    }


    /**
     * Configura o serviço de autenticação mock para fins de teste.
     * <p>
     *     Troque o valor de teste@teste.com por um e-mail válido de um usuário cadastrado no banco de dados para simular a autenticação.
     * </p>
     * @return uma instância de AutenticadorMockService
     */
    @Bean
    public AutenticadorMockService autenticadorMock() {
        return new AutenticadorMockService(usuarioService);
    }

}
