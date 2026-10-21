package br.com.jhoneferreiradev.iconfeitto.config.firebase;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.auth.FirebaseAuth;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.ClassPathResource;
import org.springframework.core.io.Resource;

import java.io.InputStream;
import java.util.Optional;

@Slf4j
@Configuration
public class FirebaseConfig {

    @Bean
    public Optional<FirebaseApp> firebaseApp() {
        try {
            if (FirebaseApp.getApps().isEmpty()) {

                Resource resource = new ClassPathResource("serviceAccountKey.json");
                InputStream serviceAccount = resource.getInputStream();

                FirebaseOptions options = new FirebaseOptions.Builder()
                        .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                        .build();

                FirebaseApp.initializeApp(options);
            }
            return Optional.of(FirebaseApp.getInstance());
        } catch (Exception ignore) {
            gerarLogInformandoQueFirebaseAuthNaoEstaConfigurado();
            return Optional.empty();
        }
    }

    public Optional<FirebaseAuth> getFirebaseAuth() {
        try {
            return Optional.of(FirebaseAuth.getInstance());
        } catch (Exception ignore) {
            gerarLogInformandoQueFirebaseAuthNaoEstaConfigurado();
            return Optional.empty();
        }
    }

    private static void gerarLogInformandoQueFirebaseAuthNaoEstaConfigurado() {
        log.info("\n\nFirebaseAuth não está configurado. Certifique-se de que o arquivo serviceAccountKey.json está presente no classpath\n\n");
    }

}

