package br.com.jhoneferreiradev.iconfeitto.api.modelo.saida.empresa.confeitaria;

import br.com.jhoneferreiradev.iconfeitto.api.modelo.saida.empresa.custooperacional.CustoOperacionalDTOSaida;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.PersonalidadeJuridica;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.Set;

@Schema(
        name = "Confeitaria",
        description = "Dados de uma confeitaria")
@NoArgsConstructor
@AllArgsConstructor
@Getter
public class ConfeitariaDTOSaida {
    @Schema(
            description = "ID único da confeitaria",
            example = "42")
    private Long id;

    @Schema(
            description = "Nome da confeitaria",
            example = "Confeitaria Doce Sabor")
    private String nome;

    @Schema(
            description = "Personalidade jurídica da confeitaria",
            example = "PF")
    private PersonalidadeJuridica personalidadeJuridica;

    @Schema(
            description = "Documento da confeitaria (CNPJ ou CPF)",
            example = "12.345.678/0001-90")
    private String documento;

    @Schema(
            description = "Endereço da confeitaria",
            example = "Rua das Flores, 123, Bairro Jardim, Cidade Exemplo, Estado Exemplo, CEP 12345-678")
    private String endereco;

    @Schema(
            description = "Telefone da confeitaria",
            example = "(11) 98765-4321")
    private String telefone;

    @Schema(
            description = "Facebook da confeitaria",
            example = "facebook.com/doce-sabor")
    private String facebook;

    @Schema(
            description = "Instagram da confeitaria",
            example = "instagram.com/doce-sabor")
    private String instagram;

    @Schema(
            description = "Custos operacionais da confeitaria")
    private Set<CustoOperacionalDTOSaida> custosOperacionais;
}
