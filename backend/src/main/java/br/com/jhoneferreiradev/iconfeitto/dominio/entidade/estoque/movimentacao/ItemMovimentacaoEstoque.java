package br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao;

import br.com.jhoneferreiradev.iconfeitto.dominio.EntidadeBase;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.item.Item;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.unidademedida.UnidadeMedida;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.util.UUID;

@EqualsAndHashCode(callSuper = true, onlyExplicitlyIncluded = true)
@Data
@Entity
@Table(name = "tb_item_movimentacao_estoque")
@NoArgsConstructor
public class ItemMovimentacaoEstoque extends EntidadeBase {

    @Setter(AccessLevel.NONE)
    @Transient
    @EqualsAndHashCode.Include
    private String uid = UUID.randomUUID().toString();

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "movimentacao_estoque_id")
    private MovimentacaoEstoque movimentacaoEstoque;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "item_id")
    private Item item;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "unidade_medida_id")
    private UnidadeMedida unidadeMedida;

    private BigDecimal quantidade;

    private BigDecimal valorUnitario;

    public ItemMovimentacaoEstoque(Long id, String uid, MovimentacaoEstoque movimentacaoEstoque, Item item,
                                   UnidadeMedida unidadeMedida, BigDecimal quantidade, BigDecimal valorUnitario) {
        super(id);
        this.uid = uid;
        this.movimentacaoEstoque = movimentacaoEstoque;
        this.item = item;
        this.unidadeMedida = unidadeMedida;
        this.quantidade = quantidade;
        this.valorUnitario = valorUnitario;
    }
}
