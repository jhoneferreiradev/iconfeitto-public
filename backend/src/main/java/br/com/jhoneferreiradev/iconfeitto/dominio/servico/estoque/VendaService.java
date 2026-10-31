package br.com.jhoneferreiradev.iconfeitto.dominio.servico.estoque;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao.venda.StatusVenda;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao.venda.Venda;
import br.com.jhoneferreiradev.iconfeitto.dominio.servico.base.ServicoBase;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

import java.time.OffsetDateTime;

public interface VendaService extends ServicoBase<Venda> {

    Venda atualizarStatus(AtualizacaoStatusDTO atualizacaoStatus);

    @AllArgsConstructor
    @NoArgsConstructor
    @Data
    @EqualsAndHashCode
    class AtualizacaoStatusDTO {
        private Long id;
        private StatusVenda statusVenda;
        private OffsetDateTime dataEntrega;
    }

}
