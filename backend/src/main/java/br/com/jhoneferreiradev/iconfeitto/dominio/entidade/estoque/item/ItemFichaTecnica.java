package br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.item;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.EntidadeBase;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.unidademedida.UnidadeMedida;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.util.UUID;

@EqualsAndHashCode(callSuper = true, onlyExplicitlyIncluded = true)
@Data
@Entity
@Table(name = "tb_item_ficha_tecnica")
@NoArgsConstructor
public class ItemFichaTecnica extends EntidadeBase {

    @Setter(AccessLevel.NONE)
    @Transient
    @EqualsAndHashCode.Include
    private String uid = UUID.randomUUID().toString();

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "item_principal_id")
    private Item itemPrincipal;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "item_composicao_id")
    private Item itemComposicao;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "unidade_medida_id")
    private UnidadeMedida unidadeMedida;

    private BigDecimal quantidade;


    public ItemFichaTecnica(Long id, Item itemPrincipal, Item itemComposicao, UnidadeMedida unidadeMedida,
                            BigDecimal quantidade) {
        super(id);
        this.itemPrincipal = itemPrincipal;
        this.itemComposicao = itemComposicao;
        this.unidadeMedida = unidadeMedida;
        this.quantidade = quantidade;
    }
}