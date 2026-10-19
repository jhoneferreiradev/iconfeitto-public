package br.com.jhoneferreiradev.iconfeitto.dominio.entidade.financeiro.quitacao;

import br.com.jhoneferreiradev.iconfeitto.dominio.EntidadeBase;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.financeiro.FormaPagamento;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.financeiro.lancamentofinanceiro.LancamentoFinanceiro;
import jakarta.persistence.*;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

@EqualsAndHashCode(callSuper = true, onlyExplicitlyIncluded = true)
@Data
@Entity
@Table(name = "tb_quitacao")
@NoArgsConstructor
public class Quitacao extends EntidadeBase {
    @ManyToOne(fetch = FetchType.LAZY)
    private LancamentoFinanceiro lancamento;
    private OffsetDateTime dataQuitacao;
    private BigDecimal valorQuitado;
    @Enumerated(EnumType.STRING)
    private FormaPagamento formaPagamento;

    public Quitacao(Long id, LancamentoFinanceiro lancamento, OffsetDateTime dataQuitacao, BigDecimal valorQuitado,
                    FormaPagamento formaPagamento) {
        super(id);
        this.lancamento = lancamento;
        this.dataQuitacao = dataQuitacao;
        this.valorQuitado = valorQuitado;
        this.formaPagamento = formaPagamento;
    }
}
