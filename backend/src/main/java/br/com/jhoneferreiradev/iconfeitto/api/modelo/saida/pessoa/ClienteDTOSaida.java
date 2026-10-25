package br.com.jhoneferreiradev.iconfeitto.api.modelo.saida.pessoa;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Schema(
        name = "Cliente",
        description = "Dados de um cliente")
@JsonIgnoreProperties(ignoreUnknown = true)
@EqualsAndHashCode(callSuper = true)
@Getter
@NoArgsConstructor
public class ClienteDTOSaida extends AbstractPessoaDTOSaida {

    public ClienteDTOSaida(Long id,
                           String nome,
                           Boolean ativo) {
        super(id, nome, ativo);
    }
}
