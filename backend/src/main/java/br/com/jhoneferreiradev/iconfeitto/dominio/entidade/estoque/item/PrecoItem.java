package br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.item;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.EntidadeBase;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

@EqualsAndHashCode(callSuper = true, onlyExplicitlyIncluded = true)
@Data
@Entity
@Table(name = "tb_preco_item")
@NoArgsConstructor
public class PrecoItem extends EntidadeBase {

    @Setter(AccessLevel.NONE)
    @Transient
    @EqualsAndHashCode.Include
    private String uid = UUID.randomUUID().toString();

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "item_id")
    private Item item;
    private BigDecimal precoUnitario;
    private OffsetDateTime dataInicio;

    public PrecoItem(Long id, Item item, BigDecimal precoUnitario, OffsetDateTime dataInicio) {
        super(id);
        this.item = item;
        this.precoUnitario = precoUnitario;
        this.dataInicio = dataInicio;
    }
}
