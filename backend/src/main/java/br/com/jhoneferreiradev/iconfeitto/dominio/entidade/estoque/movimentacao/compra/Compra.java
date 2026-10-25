package br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao.compra;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.empresa.confeitaria.Confeitaria;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao.ItemMovimentacaoEstoque;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao.MovimentacaoEstoque;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao.TipoMovimentacaoEstoque;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.fornecedor.Fornecedor;
import jakarta.persistence.*;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

import java.time.OffsetDateTime;
import java.util.Set;

@EqualsAndHashCode(callSuper = true, onlyExplicitlyIncluded = true)
@Data
@Entity
@Table(name = "tb_compra")
@DiscriminatorValue("00") // 00 = TipoMovimentacaoEstoque.COMPRA.getId()
@PrimaryKeyJoinColumn(name = "id")
@NoArgsConstructor
public class Compra extends MovimentacaoEstoque {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "fornecedor_id")
    private Fornecedor fornecedor;

    @OneToMany(mappedBy = "movimentacaoEstoque", cascade = CascadeType.ALL, orphanRemoval = true)
    private Set<ItemMovimentacaoEstoque> itens;

    public Compra(Long id, Confeitaria confeitaria, OffsetDateTime criadoEm, OffsetDateTime data,
                  TipoMovimentacaoEstoque tipoMovimentacao, Fornecedor fornecedor,
                  Set<ItemMovimentacaoEstoque> itens) {
        super(id, confeitaria, criadoEm, data, tipoMovimentacao);
        this.fornecedor = fornecedor;
        this.itens = itens;
    }
}
