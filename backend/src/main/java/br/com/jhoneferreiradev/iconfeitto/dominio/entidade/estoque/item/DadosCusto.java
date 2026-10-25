package br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.item;

import jakarta.persistence.Embeddable;
import jakarta.persistence.Transient;
import lombok.*;

import java.math.BigDecimal;
import java.util.UUID;

@Embeddable
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
@Data
@NoArgsConstructor
public class DadosCusto {

    @Setter(AccessLevel.NONE)
    @Transient
    @EqualsAndHashCode.Include
    private String uid = UUID.randomUUID().toString();

    private BigDecimal custoMedio;
    private BigDecimal custoEmbalagem;
    private BigDecimal custoOperacional;

    public DadosCusto(BigDecimal custoMedio, BigDecimal custoEmbalagem, BigDecimal custoOperacional) {
        this.custoMedio = custoMedio;
        this.custoEmbalagem = custoEmbalagem;
        this.custoOperacional = custoOperacional;
    }
}
