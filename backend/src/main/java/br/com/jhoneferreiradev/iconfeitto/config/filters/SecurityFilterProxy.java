package br.com.jhoneferreiradev.iconfeitto.config.filters;

import br.com.jhoneferreiradev.iconfeitto.config.security.SecurityConfigUtil;
import br.com.jhoneferreiradev.iconfeitto.dominio.excecao.IConfeittoException;
import com.google.firebase.auth.FirebaseAuthException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpStatus;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

import static br.com.jhoneferreiradev.iconfeitto.config.security.SecurityConfigUtil.PATH_MATCHER;

@Configuration
public class SecurityFilterProxy extends OncePerRequestFilter {

    @Autowired
    private FiltroBaseConfig filtroBaseConfig;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {

        try {

            filtroBaseConfig.aplicarFiltro(request, response, filterChain, this);

        } catch (FirebaseAuthException e) {
            throw new IConfeittoException("Acesso não autorizado", HttpStatus.UNAUTHORIZED);
        }

    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest req) throws ServletException {

        String metodo = req.getMethod();
        String caminho = req.getRequestURI().substring(req.getContextPath().length());

        boolean isPublica = SecurityConfigUtil.listarRequisicoesPublicas().stream().anyMatch(publica ->
                publica.metodo().matches(metodo)
                        && PATH_MATCHER.match(publica.url(), caminho));

        if (isPublica) {
            return true;
        }

        return super.shouldNotFilter(req);
    }


}
