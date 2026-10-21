package br.com.jhoneferreiradev.iconfeitto.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.core.env.Environment;

@Configuration
public class AmbienteServiceProvider {
    private final Environment environment;

    public AmbienteServiceProvider(Environment environment) {
        this.environment = environment;
    }

    public boolean isDev() {
        return environment.matchesProfiles("dev");
    }

    public boolean isProd() {
        return environment.matchesProfiles("prod");
    }

    public String[] getProfilesAtivos() {
        return environment.getActiveProfiles();
    }
}
