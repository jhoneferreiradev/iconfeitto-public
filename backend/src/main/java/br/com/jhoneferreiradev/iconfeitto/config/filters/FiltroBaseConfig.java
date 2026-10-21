package br.com.jhoneferreiradev.iconfeitto.config.filters;


import br.com.jhoneferreiradev.iconfeitto.config.autenticador.AutenticadorService;
import br.com.jhoneferreiradev.iconfeitto.config.autenticador.mock.AutenticadorMockService;
import br.com.jhoneferreiradev.iconfeitto.dominio.excecao.IConfeittoException;
import com.google.firebase.auth.FirebaseAuthException;
import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpStatus;

import java.io.IOException;

@Slf4j
@Configuration
public class FiltroBaseConfig {

    /**
     * AutenticadorService é uma interface que define o contrato para autenticação de usuários.
     * <p>
     * Use autenticadorFirebase para autenticação real com Firebase. Será necessário criar uma conta no Firebase e gerar um arquivo de chave de serviço (serviceAccountKey.json) para autenticação.
     * </p>
     *
     * <p>
     * Use autenticadorMock para fins de teste. Troque o valor de teste@teste.com por um e-mail válido de um usuário cadastrado no banco de dados para simular a autenticação.
     * </p>
     *
     * <p>
     * Caso precise incluir novo autenticador, basta criar uma nova implementação da interface AutenticadorService e configurar o bean correspondente.
     * </p>
     */
    @Autowired
    @Qualifier("autenticadorFirebase")
    private AutenticadorService autenticadorService;

    public void aplicarFiltro(HttpServletRequest request,
                              HttpServletResponse response,
                              FilterChain filterChain,
                              Filter filter) throws ServletException, IOException, FirebaseAuthException {

        if (autenticadorService instanceof AutenticadorMockService) {
            log.info("\n\n Autenticador de teste em utilização !!! \n\n");
        }

        if ("OPTIONS".equalsIgnoreCase(request.getMethod())) {
            filter.doFilter(request, response, filterChain);
            return;
        }


        String authorization = request.getHeader("Authorization");
        if (authorization == null || !authorization.startsWith("Bearer ")) {
            throw new IConfeittoException("Acesso não autorizado", HttpStatus.UNAUTHORIZED);
        }

        String authorizationToken = authorization.replace("Bearer ", "").trim();

        log.info(authorizationToken);

        autenticadorService.autenticar(authorizationToken);

        filter.doFilter(request, response, filterChain);
    }
}
