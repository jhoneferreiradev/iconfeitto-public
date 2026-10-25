package br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.empresa.confeitaria;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.PersonalidadeJuridica;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import io.swagger.v3.oas.annotations.media.Schema;

@Schema(
        name = "Confeitaria",
        description = "Dados para a atualização de uma confeitaria. " +
                "Atributos nulos ou não informados, serão ignorados e não sobrescreverão os valores existentes")
@JsonIgnoreProperties(ignoreUnknown = true)
public record ConfeitariaDTOEntrada(
        @Schema(
                requiredMode = Schema.RequiredMode.NOT_REQUIRED,
                description = "Nome da confeitaria",
                example = "Confeitaria Doce Sabor")
        String nome,

        @Schema(
                requiredMode = Schema.RequiredMode.NOT_REQUIRED,
                description = "Personalidade jurídica da confeitaria",
                example = "PF")
        PersonalidadeJuridica personalidadeJuridica,

        @Schema(
                requiredMode = Schema.RequiredMode.NOT_REQUIRED,
                description = "Documento da confeitaria (CNPJ ou CPF)",
                example = "12.345.678/0001-90")
        String documento,

        @Schema(
                requiredMode = Schema.RequiredMode.NOT_REQUIRED,
                description = "Endereço da confeitaria",
                example = "Rua das Flores, 123, Bairro Jardim, Cidade Exemplo, Estado Exemplo, CEP 12345-678")
        String endereco,

        @Schema(
                requiredMode = Schema.RequiredMode.NOT_REQUIRED,
                description = "Telefone da confeitaria",
                example = "(11) 98765-4321")
        String telefone,

        @Schema(
                requiredMode = Schema.RequiredMode.NOT_REQUIRED,
                description = "Email da confeitaria",
                example = "contato@doce-sabor.com")
        String email,

        @Schema(
                requiredMode = Schema.RequiredMode.NOT_REQUIRED,
                description = "Facebook da confeitaria",
                example = "facebook.com/doce-sabor")
        String facebook,

        @Schema(
                requiredMode = Schema.RequiredMode.NOT_REQUIRED,
                description = "Instagram da confeitaria",
                example = "instagram.com/doce-sabor")
        String instagram
) {
}
