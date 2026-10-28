package br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao.fabricacao;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.empresa.confeitaria.Confeitaria;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.item.Item;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao.ItemMovimentacaoEstoque;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao.MovimentacaoEstoque;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao.TipoMovimentacaoEstoque;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao.venda.Venda;
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
@Table(name = "tb_fabricacao")
@DiscriminatorValue("FABRICACAO") // 02 = TipoMovimentacaoEstoque.FABRICACAO.getId()
@PrimaryKeyJoinColumn(name = "id")
@NoArgsConstructor
public class Fabricacao extends MovimentacaoEstoque {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "item_principal_id")
    private Item itemPrincipal;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "fabricacao_pai_id")
    private Fabricacao fabricacaoPai;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "venda_id")
    private Venda venda;

    private BigDecimal quantidade;

    @OneToMany(mappedBy = "movimentacaoEstoque", cascade = CascadeType.ALL, orphanRemoval = true)
    private Set<ItemMovimentacaoEstoque> itens;

    public Fabricacao(Long id, Confeitaria confeitaria, OffsetDateTime criadoEm, OffsetDateTime data,
                      TipoMovimentacaoEstoque tipoMovimentacao, Item itemPrincipal,
                      Fabricacao fabricacaoPai, Venda venda, BigDecimal quantidade,
                      Set<ItemMovimentacaoEstoque> itens) {
        super(id, confeitaria, criadoEm, data, tipoMovimentacao);
        this.itemPrincipal = itemPrincipal;
        this.fabricacaoPai = fabricacaoPai;
        this.venda = venda;
        this.quantidade = quantidade;
        this.itens = itens;
    }
}
