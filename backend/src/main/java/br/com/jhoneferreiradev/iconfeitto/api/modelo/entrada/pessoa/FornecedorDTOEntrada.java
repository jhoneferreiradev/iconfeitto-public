package br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.pessoa;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.PersonalidadeJuridica;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.EqualsAndHashCode;
import lombok.Getter;

@Schema(
        name = "Fornecedor",
        description = "Dados para a criação ou atualização de um fornecedor. " +
                "Na atualização, atributos nulos ou não informados serão ignorados e não sobrescreverão os valores existentes",
        allOf = AbstractPessoaDTOEntrada.class)
@JsonIgnoreProperties(ignoreUnknown = true)
@EqualsAndHashCode(callSuper = true)
@Getter
public class FornecedorDTOEntrada extends AbstractPessoaDTOEntrada {

    public FornecedorDTOEntrada(String nome,
                                PersonalidadeJuridica personalidadeJuridica,
                                Boolean ativo) {
        super(nome, personalidadeJuridica, ativo);
    }
}
