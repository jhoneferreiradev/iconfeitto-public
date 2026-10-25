package br.com.jhoneferreiradev.iconfeitto.api.config;

import br.com.jhoneferreiradev.iconfeitto.api.modelo.conversordeobjeto.MapeamentoDeConversaoDeObjeto;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.estoque.item.DadosCustoDTOEntrada;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.estoque.item.DadosEstoqueDTOEntrada;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.estoque.item.DadosFichaTecnicaDTOEntrada;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.saida.estoque.item.DadosCustoDTOSaida;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.saida.estoque.item.DadosEstoqueDTOSaida;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.saida.estoque.item.DadosFichaTecnicaDTOSaida;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.item.DadosCusto;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.item.DadosEstoque;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.item.DadosFichaTecnica;
import lombok.NoArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
@NoArgsConstructor
public class MapeamentoDeConversaoDeObjetoConfig {

    @Bean
    public MapeamentoDeConversaoDeObjeto getMapeamentoDeConversaoDeObjeto() {
        return new MapeamentoDeConversaoDeObjeto()

                .registrar(DadosEstoqueDTOEntrada.class, DadosEstoque.class)
                .registrar(DadosEstoque.class, DadosEstoqueDTOSaida.class)

                .registrar(DadosFichaTecnicaDTOEntrada.class, DadosFichaTecnica.class)
                .registrar(DadosFichaTecnica.class, DadosFichaTecnicaDTOSaida.class)

                .registrar(DadosCustoDTOEntrada.class, DadosCusto.class)
                .registrar(DadosCusto.class, DadosCustoDTOSaida.class)

                ;

    }
}
