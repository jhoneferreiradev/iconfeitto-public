package br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.pessoa;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Schema(
        name = "Cliente",
        description = "Dados para a criação ou atualização de um cliente. " +
                "Na atualização, atributos nulos ou não informados serão ignorados e não sobrescreverão os valores existentes",
        allOf = AbstractPessoaDTOEntrada.class)
@JsonIgnoreProperties(ignoreUnknown = true)
@EqualsAndHashCode(callSuper = true)
@Getter
@NoArgsConstructor
public class ClienteDTOEntrada extends AbstractPessoaDTOEntrada {

    public ClienteDTOEntrada(String nome,
                             Boolean ativo) {
        super(nome, ativo);
    }
}
