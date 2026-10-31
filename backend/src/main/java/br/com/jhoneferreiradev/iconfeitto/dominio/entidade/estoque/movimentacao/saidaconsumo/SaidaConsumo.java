package br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao.saidaconsumo;

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
@Table(name = "tb_saida_consumo")
@DiscriminatorValue("SAIDA_CONSUMO") // 03 = TipoMovimentacaoEstoque.SAIDA_CONSUMO.getId()
@PrimaryKeyJoinColumn(name = "id")
@NoArgsConstructor
public class SaidaConsumo extends MovimentacaoEstoque {

    private OffsetDateTime dataConsumo;

    @OneToMany(mappedBy = "movimentacaoEstoque", cascade = CascadeType.ALL, orphanRemoval = true)
    private Set<ItemMovimentacaoEstoque> itens;

    public SaidaConsumo(Long id, Confeitaria confeitaria, OffsetDateTime criadoEm, OffsetDateTime dataConsumo,
                        TipoMovimentacaoEstoque tipoMovimentacao, Set<ItemMovimentacaoEstoque> itens) {
        super(id, confeitaria, criadoEm, tipoMovimentacao);
        this.dataConsumo = dataConsumo;
        this.itens = itens;
    }

    @Override
    public Optional<OffsetDateTime> getDataMovimentacao() {
        return Optional.ofNullable(dataConsumo);
    }
}
