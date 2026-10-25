package br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao.ajuste;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.empresa.confeitaria.Confeitaria;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao.ItemMovimentacaoEstoque;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao.MovimentacaoEstoque;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao.TipoMovimentacaoEstoque;
import jakarta.persistence.*;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

import java.time.OffsetDateTime;
import java.util.Set;

@EqualsAndHashCode(callSuper = true, onlyExplicitlyIncluded = true)
@Data
@Entity
@Table(name = "tb_ajuste_saida")
@DiscriminatorValue("05") // 05 = TipoMovimentacaoEstoque.AJUSTE_SAIDA.getId()
@PrimaryKeyJoinColumn(name = "id")
@NoArgsConstructor
public class AjusteSaida extends MovimentacaoEstoque {

    @OneToMany(mappedBy = "movimentacaoEstoque", cascade = CascadeType.ALL, orphanRemoval = true)
    private Set<ItemMovimentacaoEstoque> itens;

    public AjusteSaida(Long id, Confeitaria confeitaria, OffsetDateTime criadoEm, OffsetDateTime data,
                       TipoMovimentacaoEstoque tipoMovimentacao, Set<ItemMovimentacaoEstoque> itens) {
        super(id, confeitaria, criadoEm, data, tipoMovimentacao);
        this.itens = itens;
    }
}
