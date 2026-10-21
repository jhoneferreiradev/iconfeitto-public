package br.com.jhoneferreiradev.iconfeitto.config.filters;


import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.web.filter.CorsFilter;

import java.util.Arrays;
import java.util.Collections;

@Configuration
public class CorsConfig { // 👈 Remova o "implements WebMvcConfigurer"

    @Bean
    public CorsFilter corsFilter() {
        UrlBasedCorsConfigurationSource origem = new UrlBasedCorsConfigurationSource();
        CorsConfiguration config = new CorsConfiguration();

        config.setAllowCredentials(true);
        // Suas origens permitidas

        // config.setAllowedOrigins(Arrays.asList("http://localhost:8080", "https://seu-dominio.com.br"));
        config.setAllowedOrigins(Arrays.asList("http://localhost:8080"));

        // Aceita todos os métodos (GET, POST, OPTIONS, etc)
        config.setAllowedMethods(Collections.singletonList("*"));

        // Aceita todos os headers para garantir que nenhum customizado bloqueie o preflight
        config.setAllowedHeaders(Collections.singletonList("*"));

        // Aplica essa configuração para todas as rotas
        origem.registerCorsConfiguration("/**", config);
        return new CorsFilter(origem);
    }
}