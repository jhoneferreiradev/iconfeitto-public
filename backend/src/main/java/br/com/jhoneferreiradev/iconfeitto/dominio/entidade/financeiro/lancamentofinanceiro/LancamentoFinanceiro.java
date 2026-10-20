package br.com.jhoneferreiradev.iconfeitto.dominio.entidade.financeiro.lancamentofinanceiro;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.EntidadeBaseComDadosPadraoComConfeitaria;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao.MovimentacaoEstoque;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.financeiro.FormaPagamento;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.financeiro.quitacao.Quitacao;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.Pessoa;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.empresa.confeitaria.Confeitaria;
import jakarta.persistence.*;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.Set;

@EqualsAndHashCode(callSuper = true, onlyExplicitlyIncluded = true)
@Data
@Entity
@Table(name = "tb_lancamento_financeiro")
@NoArgsConstructor
public class LancamentoFinanceiro extends EntidadeBaseComDadosPadraoComConfeitaria {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "pessoa_id")
    private Pessoa pessoa;

    @Enumerated(EnumType.STRING)
    private TipoLancamentoFinanceiro tipoLancamento;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "lancamento_pai_id")
    private LancamentoFinanceiro lancamentoPai;

    @Enumerated(EnumType.STRING)
    private StatusLancamentoFinanceiro statusLancamento;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "movimentacao_estoque_id")
    private MovimentacaoEstoque movimentacaoEstoque;

    @Enumerated(EnumType.STRING)
    private FormaPagamento formaPagamento;

    private OffsetDateTime dataLancamento;
    private OffsetDateTime dataVencimento;
    private OffsetDateTime dataCompensacao;

    private String descricao;
    private String observacao;

    private BigDecimal valorLancamento;
    private BigDecimal valorDesconto;
    private BigDecimal valorAcrescimo;

    @OneToMany(mappedBy = "lancamento", cascade = CascadeType.ALL, orphanRemoval = true)
    private Set<Quitacao> quitacoes;

    public LancamentoFinanceiro(Long id, Confeitaria confeitaria, OffsetDateTime criadoEm, Pessoa pessoa,
                                TipoLancamentoFinanceiro tipoLancamento, LancamentoFinanceiro lancamentoPai,
                                StatusLancamentoFinanceiro statusLancamento, MovimentacaoEstoque movimentacaoEstoque,
                                FormaPagamento formaPagamento, OffsetDateTime dataLancamento,
                                OffsetDateTime dataVencimento, OffsetDateTime dataCompensacao, String descricao,
                                String observacao, BigDecimal valorLancamento, BigDecimal valorDesconto,
                                BigDecimal valorAcrescimo, Set<Quitacao> quitacoes) {
        super(id, confeitaria, criadoEm);
        this.pessoa = pessoa;
        this.tipoLancamento = tipoLancamento;
        this.lancamentoPai = lancamentoPai;
        this.statusLancamento = statusLancamento;
        this.movimentacaoEstoque = movimentacaoEstoque;
        this.formaPagamento = formaPagamento;
        this.dataLancamento = dataLancamento;
        this.dataVencimento = dataVencimento;
        this.dataCompensacao = dataCompensacao;
        this.descricao = descricao;
        this.observacao = observacao;
        this.valorLancamento = valorLancamento;
        this.valorDesconto = valorDesconto;
        this.valorAcrescimo = valorAcrescimo;
        this.quitacoes = quitacoes;
    }
}
