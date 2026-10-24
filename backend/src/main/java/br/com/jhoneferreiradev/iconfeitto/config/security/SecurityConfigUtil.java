package br.com.jhoneferreiradev.iconfeitto.config.security;


import org.springframework.http.HttpMethod;
import org.springframework.util.AntPathMatcher;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Set;

public class SecurityConfigUtil {

    public static final AntPathMatcher PATH_MATCHER = new AntPathMatcher();

    public record RequisicaoPublica(HttpMethod metodo, String url) {
    }

    public static List<RequisicaoPublica> listarRequisicoesPublicas() {
        List<RequisicaoPublica> lista =
                new ArrayList<>(Arrays.asList(

                        new RequisicaoPublica(HttpMethod.POST, "/confeitarias"),
                        new RequisicaoPublica(HttpMethod.POST, "/confeitarias/ativacoes"),
                        new RequisicaoPublica(HttpMethod.GET, "/confeitarias/ativacoes")

                ));

        for (String urlPublica : listarUrlsPublicas()) {
            lista.addAll(
                    Arrays.stream(HttpMethod.values())
                            .map(metodo -> new RequisicaoPublica(metodo, urlPublica))
                            .toList()

            );
        }


        return lista;
    }

    public static Set<String> listarUrlsPublicas() {
        return Set.of(
                "/v3/api-docs/**",
                "/swagger-ui/**",
                "/swagger-ui.html",
                "/webjars/**"
        );
    }
}