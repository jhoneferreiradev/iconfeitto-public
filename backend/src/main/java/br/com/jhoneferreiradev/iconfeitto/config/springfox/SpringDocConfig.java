package br.com.jhoneferreiradev.iconfeitto.config.springfox;

import br.com.jhoneferreiradev.iconfeitto.dominio.excecao.modelo.IConfeittoErro;
import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.media.Schema;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class SpringDocConfig {

    @Bean
    public OpenAPI api() {
        return new OpenAPI()
                .info(new Info()
                                .title("iConfeitto API")
                                .version("1.0")
                                .summary("Documentação da API do sistema iConfeitto")
                                .description("Esta API fornece endpoints para aplicações de gerenciamento de Confeitarias. Inclui ficha técnica, estoque, faturamento e financeiro")

//                        .contact(
//                                new Contact()
//                                        .name("NOME_CONTATO")
//                                        .email("EMAIL_CONTATO")
//                                        .url("URL_SITE_CONTATO")
//                        )
                )

                .addSecurityItem(new SecurityRequirement().addList("bearerAuth"))


                .components(new Components()
                        .addSchemas("IConfeittoErro", new Schema<IConfeittoErro>()
                                .name("IConfeittoErro")
                                .description("Modelo de erro retornado pela API")
                                .example(new IConfeittoErro(400, "Campo de telefone é obrigatório")))
                        .addSecuritySchemes("bearerAuth",
                                new SecurityScheme()
                                        .type(SecurityScheme.Type.HTTP)
                                        .scheme("bearer")
                                        .bearerFormat("JWT")));
    }
}