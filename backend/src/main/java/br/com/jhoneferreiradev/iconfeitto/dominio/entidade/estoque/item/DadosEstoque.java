package br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.item;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.unidademedida.UnidadeMedida;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.util.UUID;

@Embeddable
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
@Data
@NoArgsConstructor
public class DadosEstoque {

    @Setter(AccessLevel.NONE)
    @Transient
    @EqualsAndHashCode.Include
    private String uid = UUID.randomUUID().toString();

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "unidade_medida_estoque_id")
    private UnidadeMedida unidadeMedidaEstoque;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "unidade_medida_consumo_id")
    private UnidadeMedida unidadeMedidaConsumo;

    private BigDecimal saldoEstoque;
    private BigDecimal quantidadeMinimaEstoque;

    public DadosEstoque(UnidadeMedida unidadeMedidaEstoque, UnidadeMedida unidadeMedidaConsumo,
                        BigDecimal saldoEstoque, BigDecimal quantidadeMinimaEstoque) {
        this.unidadeMedidaEstoque = unidadeMedidaEstoque;
        this.unidadeMedidaConsumo = unidadeMedidaConsumo;
        this.saldoEstoque = saldoEstoque;
        this.quantidadeMinimaEstoque = quantidadeMinimaEstoque;
    }
}
