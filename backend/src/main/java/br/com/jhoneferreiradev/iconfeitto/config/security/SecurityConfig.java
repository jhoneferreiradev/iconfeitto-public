package br.com.jhoneferreiradev.iconfeitto.config.security;


import br.com.jhoneferreiradev.iconfeitto.config.AmbienteServiceProvider;
import br.com.jhoneferreiradev.iconfeitto.config.filters.SecurityFilterProxy;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.annotation.web.configurers.HeadersConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.List;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Autowired
    private AmbienteServiceProvider ambienteServiceProvider;

    @Autowired
    private SecurityFilterProxy securityFilterProxy;

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        var config = new CorsConfiguration();
        // Suas origens permitidas
        // config.setAllowedOrigins(Arrays.asList("http://localhost:8080", "https://seu-dominio.com.br"));
        config.setAllowedOrigins(List.of("http://localhost:8080"));
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"));
        config.setAllowedHeaders(List.of("*"));
        config.setAllowCredentials(true);
        config.setMaxAge(3600L);
        var source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {

        if (ambienteServiceProvider.isDev()) {
            http.headers(hshc -> hshc.frameOptions(HeadersConfigurer.FrameOptionsConfig::disable));
        }

        return http
                .cors(Customizer.withDefaults())
                .csrf(AbstractHttpConfigurer::disable)
                .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(req -> {
                    req.requestMatchers(HttpMethod.OPTIONS, "/**").permitAll();

                    List<SecurityConfigUtil.RequisicaoPublica> requisicoesPublicas = SecurityConfigUtil.listarRequisicoesPublicas();

                    for (SecurityConfigUtil.RequisicaoPublica requisicao : requisicoesPublicas) {
                        req.requestMatchers(requisicao.metodo(), requisicao.url()).permitAll();
                    }

                    req.anyRequest().authenticated();
                })

                .addFilterBefore(securityFilterProxy, UsernamePasswordAuthenticationFilter.class)
                .build();

    }

}
