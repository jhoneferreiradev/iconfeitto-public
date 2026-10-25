package br.com.jhoneferreiradev.iconfeitto.api.modelo.saida.pessoa;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.PersonalidadeJuridica;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.EqualsAndHashCode;
import lombok.Getter;

@Schema(
        name = "Cliente",
        description = "Dados de um cliente")
@JsonIgnoreProperties(ignoreUnknown = true)
@EqualsAndHashCode(callSuper = true)
@Getter
public class ClienteDTOSaida extends AbstractPessoaDTOSaida {

    public ClienteDTOSaida(Long id,
                           String nome,
                           PersonalidadeJuridica personalidadeJuridica,
                           Boolean ativo) {
        super(id, nome, personalidadeJuridica, ativo);
    }
}
