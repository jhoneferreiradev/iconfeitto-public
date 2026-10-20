package br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.EntidadeBaseComDadosPadraoComConfeitaria;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.empresa.confeitaria.Confeitaria;
import jakarta.persistence.*;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

import java.time.OffsetDateTime;

@EqualsAndHashCode(callSuper = true, onlyExplicitlyIncluded = true)
@Data
@Entity
@Table(name = "tb_movimentacao_estoque")
@Inheritance(strategy = InheritanceType.JOINED)
@DiscriminatorColumn(name = "tipo_movimentacao", discriminatorType = DiscriminatorType.STRING)
@NoArgsConstructor
public abstract class MovimentacaoEstoque extends EntidadeBaseComDadosPadraoComConfeitaria {

    private OffsetDateTime data;

    @Enumerated(EnumType.STRING)
    @Column(name = "tipo_movimentacao", insertable = false, updatable = false)
    private TipoMovimentacaoEstoque tipoMovimentacao;

    public MovimentacaoEstoque(Long id, Confeitaria confeitaria, OffsetDateTime criadoEm,
                               OffsetDateTime data, TipoMovimentacaoEstoque tipoMovimentacao) {
        super(id, confeitaria, criadoEm);
        this.data = data;
        this.tipoMovimentacao = tipoMovimentacao;
    }
}
