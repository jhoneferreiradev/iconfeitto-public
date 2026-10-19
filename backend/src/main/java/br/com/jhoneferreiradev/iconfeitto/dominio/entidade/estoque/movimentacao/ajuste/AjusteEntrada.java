package br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao.ajuste;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao.ItemMovimentacaoEstoque;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao.MovimentacaoEstoque;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao.TipoMovimentacaoEstoque;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.confeitaria.Confeitaria;
import jakarta.persistence.*;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

import java.time.OffsetDateTime;
import java.util.Set;

@EqualsAndHashCode(callSuper = true, onlyExplicitlyIncluded = true)
@Data
@Entity
@Table(name = "tb_ajuste_entrada")
@DiscriminatorValue("04") // 04 = TipoMovimentacaoEstoque.AJUSTE_ENTRADA.getId()
@PrimaryKeyJoinColumn(name = "id")
@NoArgsConstructor
public class AjusteEntrada extends MovimentacaoEstoque {

    @OneToMany(mappedBy = "movimentacaoEstoque", cascade = CascadeType.ALL, orphanRemoval = true)
    private Set<ItemMovimentacaoEstoque> itens;

    public AjusteEntrada(Long id, Confeitaria confeitaria, OffsetDateTime criadoEm, OffsetDateTime data,
                         TipoMovimentacaoEstoque tipoMovimentacao, Set<ItemMovimentacaoEstoque> itens) {
        super(id, confeitaria, criadoEm, data, tipoMovimentacao);
        this.itens = itens;
    }
}
