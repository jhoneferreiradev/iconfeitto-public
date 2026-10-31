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
import java.util.Optional;
import java.util.Set;

@EqualsAndHashCode(callSuper = true, onlyExplicitlyIncluded = true)
@Data
@Entity
@Table(name = "tb_ajuste_entrada")
@DiscriminatorValue("AJUSTE_ENTRADA") // 04 = TipoMovimentacaoEstoque.AJUSTE_ENTRADA.getId()
@PrimaryKeyJoinColumn(name = "id")
@NoArgsConstructor
public class AjusteEntrada extends MovimentacaoEstoque {

    private OffsetDateTime dataAjuste;

    @OneToMany(mappedBy = "movimentacaoEstoque", cascade = CascadeType.ALL, orphanRemoval = true)
    private Set<ItemMovimentacaoEstoque> itens;

    public AjusteEntrada(Long id, Confeitaria confeitaria, OffsetDateTime criadoEm, OffsetDateTime dataAjuste,
                         TipoMovimentacaoEstoque tipoMovimentacao, Set<ItemMovimentacaoEstoque> itens) {
        super(id, confeitaria, criadoEm, tipoMovimentacao);
        this.dataAjuste = dataAjuste;
        this.itens = itens;
    }

    @Override
    public Optional<OffsetDateTime> getDataMovimentacao() {
        return Optional.ofNullable(dataAjuste);
    }
}
